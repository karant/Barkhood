class Person < ActiveRecord::Base
  extend PreferencesHelper

  attr_accessor :password, :verify_password, :new_password
  attr_accessible :email, :password, :password_confirmation, :connection_notifications,
                  :message_notifications, :wall_comment_notifications,
                  :blog_comment_notifications, :address, :identity_url
  MAX_EMAIL = MAX_PASSWORD = 40
  MAX_ADDRESS = 120
  EMAIL_REGEX = /\A[A-Z0-9\._%+-]+@([A-Z0-9-]+\.)+[A-Z]{2,4}\z/i
  TIME_AGO_FOR_MOSTLY_ACTIVE = 1.month.ago
  FEED_SIZE = 10

  has_many :dogs, :foreign_key => 'owner_id', :dependent => :destroy, :order => "dogs.deactivated, dogs.created_at"
  has_many :contacts, :through => :dogs, :source => :connections
  has_many :email_verifications
  has_many :_sent_messages, :through => :dogs
  has_many :_received_messages, :through => :dogs
  has_many :feeds
  has_many :activities, :through => :feeds, :order => 'activities.created_at DESC',
                                            :limit => FEED_SIZE,
                                            :conditions => ["dogs.deactivated = ?", false],
                                            :include => :dog
 
  validates_presence_of     :email, :address
  validates_presence_of     :password,              :if => :password_required?
  validates_presence_of     :password_confirmation, :if => :password_required?
  validates_length_of       :password, :within => 4..MAX_PASSWORD,
                                       :if => :password_required?
  validates_confirmation_of :password, :if => :password_required?
  validates_length_of       :email, :within => 6..MAX_EMAIL
  validates_format_of       :email,
                            :with => EMAIL_REGEX,
                            :message => "must be a valid email address"
  validates_uniqueness_of   :email
  validates_uniqueness_of   :identity_url, :allow_nil => true

  acts_as_mappable :default_units => :miles, 
                   :default_formula => :sphere, 
                   :distance_field_name => :distance,
                   :lat_column_name => :lat,
                   :lng_column_name => :lng,
                   :auto_geocode => true

  before_create :check_config_for_deactivation
  before_save :encrypt_password
  before_validation :prepare_email

  class << self
    # Return the paginated active users.
    def active(page = 1)
      paginate(:all, :page => page,
                     :per_page => RASTER_PER_PAGE,
                     :conditions => conditions_for_active)
    end
    
    # Return the people who are 'mostly' active.
    # People are mostly active if they have logged in recently enough.
    def mostly_active(page = 1)
      paginate(:all, :page => page,
                     :per_page => RASTER_PER_PAGE,
                     :conditions => conditions_for_mostly_active,
                     :order => "created_at DESC")
    end
    
    # Return *all* the active users.
    def all_active
      find(:all, :conditions => conditions_for_active)
    end
    
    def find_recent
      find(:all, :order => "people.created_at DESC",
                 :limit => NUM_RECENT)
    end
     
    # Return the first admin created.
    # We suggest using this admin as the primary administrative contact.
    def find_first_admin
      find(:first, :conditions => ["admin = ?", true],
                   :order => :created_at)
    end
  end
  
  def group_ids
    group_ids = []
    dogs.each do |dog|
      group_ids << dog.group_ids
    end
    return group_ids.flatten.uniq
  end

  ## Feeds

  # Return a activity feed for all of person's dogs.
  def feed
    len = activities.length
    if len < FEED_SIZE
      # Mix in some global activities for smaller feeds.
      global = Activity.global_feed[0...(Activity::GLOBAL_FEED_SIZE-len)]
      (activities + global).uniq.sort_by { |a| a.created_at }.reverse
    else
      activities
    end
  end

  ## Authentication methods

  # Authenticates a user by their email address and unencrypted password.
  # Returns the user or nil.
  def self.authenticate(email, password)
    u = find_by_email_and_identity_url(email.downcase.strip, nil) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  def self.encrypt(password)
    Crypto::Key.from_file("#{RAILS_ROOT}/rsa_key.pub").encrypt(password)
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password)
  end

  def decrypt(password)
    Crypto::Key.from_file("#{RAILS_ROOT}/rsa_key").decrypt(password)
  end

  def authenticated?(password)
    unencrypted_password == password
  end

  def unencrypted_password
    # The gsub trickery is to unescape the key from the DB.
    decrypt(crypted_password)#.gsub(/\\n/, "\n")
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at
  end

  # These create and unset the fields required for remembering users
  # between browser closes
  def remember_me
    remember_me_for 2.years
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    key = "#{email}--#{remember_token_expires_at}"
    self.remember_token = Digest::SHA1.hexdigest(key)
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end


  def change_password?(passwords)
    self.password_confirmation = passwords[:password_confirmation]
    self.verify_password = passwords[:verify_password]
    unless verify_password == unencrypted_password
      errors.add(:password, "is incorrect")
      return false
    end
    unless passwords[:new_password] == password_confirmation
      errors.add(:password, "does not match confirmation")
      return false
    end
    self.password = passwords[:new_password]
    save
  end

  # Return true if the person is the last remaining active admin.
  def last_admin?
    num_admins = Person.count(:conditions => ["admin = ? AND deactivated = ?",
                                              true, false])
    admin? and num_admins == 1
  end

  def active?
    if Person.global_prefs.email_verifications?
      not deactivated? and email_verified?
    else
      not deactivated?
    end
  end
  
  ## Message methods

  def received_messages(page = 1)
    _received_messages.paginate(:page => page, :per_page => Dog::MESSAGES_PER_PAGE)
  end

  def sent_messages(page = 1)
    _sent_messages.paginate(:page => page, :per_page => Dog::MESSAGES_PER_PAGE)
  end

  def trashed_messages(page = 1)
    conditions = [%((sender_id IN (:dog_ids) AND sender_deleted_at > :t) OR
                    (recipient_id IN (:dog_ids) AND recipient_deleted_at > :t)),
                  { :dog_ids => dog_ids, :t => Dog::TRASH_TIME_AGO }]
    order = 'created_at DESC'
    trashed = Message.paginate(:all, :conditions => conditions,
                                     :order => order,
                                     :page => page,
                                     :per_page => Dog::MESSAGES_PER_PAGE)
  end

  def recent_messages
    Message.find(:all,
                 :conditions => [%(recipient_id IN (?) AND
                                   recipient_deleted_at IS NULL), dog_ids],
                 :order => "created_at DESC",
                 :limit => Dog::NUM_RECENT_MESSAGES)
  end  
  
  def has_unread_messages?
    sql = %(recipient_id IN (:dog_ids)
            AND sender_id NOT IN (:dog_ids)
            AND recipient_deleted_at IS NOT NULL
            AND recipient_read_at IS NULL)
    conditions = [sql, { :dog_ids => dog_ids }]
    Message.count(:all, :conditions => conditions) > 0
  end  
  
  # Return the common connections with the given dog.
  def common_contacts_with(other_dog, options = {})
    # I tried to do this in SQL for efficiency, but failed miserably.
    # Horrifyingly, MySQL lacks support for the INTERSECT keyword.
    common_contacts = []
    dogs.each do |dog|
      common_contacts << (dog.contacts & other_dog.contacts)
    end
    return common_contacts.flatten.uniq.paginate(options)
  end  
  
  protected

    ## Callbacks

    # Prepare email for database insertion.
    def prepare_email
      self.email = email.downcase.strip if email
    end

    def encrypt_password
      return if password.blank?
      self.crypted_password = encrypt(password)
    end

    def check_config_for_deactivation
      if Person.global_prefs.whitelist?
        self.deactivated = true
      end
    end

    ## Other private method(s)

    def password_required?
      (crypted_password.blank? && identity_url.nil?) || !password.blank? ||
      !verify_password.nil?
    end
    
    class << self
    
      # Return the conditions for a user to be active.
      def conditions_for_active
        [%(deactivated = ? AND 
           (email_verified IS NULL OR email_verified = ?)),
         false, true]
      end
      
      # Return the conditions for a user to be 'mostly' active.
      def conditions_for_mostly_active
        [%(deactivated = ? AND 
           (email_verified IS NULL OR email_verified = ?) AND
           (last_logged_in_at IS NOT NULL AND
            last_logged_in_at >= ?)),
         false, true, TIME_AGO_FOR_MOSTLY_ACTIVE]
      end
    end
end
