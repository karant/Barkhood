class Dog < ActiveRecord::Base
  include ActivityLogger
  extend PreferencesHelper

  attr_accessor :sorted_photos
  attr_accessible :name, :description, :dob, :breed_id, :identity_url
  # Indexed fields for Sphinx
  is_indexed :fields => [ 'name', 'description', 'deactivated'],
             :include => [
               {:association_name => 'breed', :field => 'name', :as => 'breed_name'}
             ],
             :conditions => "deactivated = false"
  MAX_NAME = 40
  MAX_DESCRIPTION = 5000
  TRASH_TIME_AGO = 1.month.ago
  SEARCH_LIMIT = 20
  SEARCH_PER_PAGE = 8
  MESSAGES_PER_PAGE = 5
  NUM_RECENT_MESSAGES = 4
  NUM_WALL_COMMENTS = 10
  NUM_RECENT = 8
  FEED_SIZE = 10
  MAX_DEFAULT_CONTACTS = 12
  TIME_AGO_FOR_MOSTLY_ACTIVE = 1.month.ago
  # These constants should be methods, but I couldn't figure out how to use
  # methods in the has_many associations.  I hope you can do better.
  ACCEPTED_AND_ACTIVE =  [%(connections.status = ? AND
                            dogs.deactivated = ? AND
                            people.deactivated = ?),
                          Connection::ACCEPTED, false, false]
  REQUESTED_AND_ACTIVE =  [%(connections.status = ? AND
                            dogs.deactivated = ? AND
                            people.deactivated = ?),
                          Connection::REQUESTED, false, false]

  belongs_to  :owner, :class_name => 'Person', :foreign_key => 'owner_id'
  belongs_to  :breed
  
  has_one :blog
  has_many :email_verifications
  has_many :comments, :as => :commentable, :order => 'created_at DESC',
                      :limit => NUM_WALL_COMMENTS
  has_many :connections
  has_many :contacts, :through => :connections,
                      :include => [:owner],
                      :conditions => ACCEPTED_AND_ACTIVE,
                      :order => 'dogs.created_at DESC'
  has_many :photos, :dependent => :destroy, :order => 'created_at'
  has_many :requested_contacts, :through => :connections,
                                :include => [:owner],
                                :source => :contact,
                                :conditions => REQUESTED_AND_ACTIVE
  with_options :class_name => "Message", :dependent => :destroy,
               :order => 'created_at DESC' do |dog|
    dog.has_many :_sent_messages, :foreign_key => "sender_id",
                 :conditions => "sender_deleted_at IS NULL"
    dog.has_many :_received_messages, :foreign_key => "recipient_id",
                 :conditions => "recipient_deleted_at IS NULL"
  end
  has_many :feeds
  has_many :activities, :through => :feeds, :order => 'activities.created_at DESC',
                                            :limit => FEED_SIZE,
                                            :conditions => ["dogs.deactivated = ?", false],
                                            :include => :dog

  has_many :page_views, :order => 'created_at DESC'
  has_many :galleries
  has_many :events
  has_many :event_attendees
  has_many :attendee_events, :through => :event_attendees, :source => :event

  validates_presence_of     :name
  validates_length_of       :name,  :maximum => MAX_NAME
  validates_length_of       :description, :maximum => MAX_DESCRIPTION
  validates_uniqueness_of   :identity_url, :allow_nil => true

  before_create :create_blog
  before_validation :handle_nil_description

  before_update :set_old_description
  after_update :log_activity_description_changed
  before_destroy :destroy_activities, :destroy_feeds

  class << self

    # Return the paginated active dogs.
    def active(page = 1)
      paginate(:all, :include => [:owner],
                     :page => page,
                     :per_page => RASTER_PER_PAGE,
                     :conditions => conditions_for_active)
    end
    
    # Return the dogs who are 'mostly' active.
    # Dogs are mostly active if their owner/user has logged in recently enough.
    def mostly_active(page = 1)
      paginate(:all, :page => page,
                     :include => [:owner],
                     :per_page => RASTER_PER_PAGE,
                     :conditions => conditions_for_mostly_active,
                     :order => "dogs.created_at DESC")
    end
    
    # Return *all* the active dogs.
    def all_active
      find(:all, :include => [:owner], :conditions => conditions_for_active)
    end
    
    def find_recent
      find(:all, :order => "dogs.created_at DESC",
                 :include => :photos, :limit => NUM_RECENT)
    end
  end

  # Params for use in urls.
  # Profile urls have the form '/dogs/1-dana'.
  # This works automagically because Dog.find(params[:id]) implicitly
  # converts params[:id] into an int, and in Ruby
  # '1-dana'.to_i == 1
  def to_param
    "#{id}-#{name.to_safe_uri rescue nil}"
  end

  ## Feeds

  # Return a dog-specific activity feed.
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

  def recent_activity
    Activity.find_all_by_dog_id(self, :order => 'created_at DESC',
                                      :limit => FEED_SIZE)
  end

  ## For the home page...

  # Return some contacts for the home page.
  def some_contacts
    contacts[(0...MAX_DEFAULT_CONTACTS)]
  end

  # Contact links for the contact image raster.
  def requested_contact_links
    requested_contacts.map do |p|
      conn = Connection.conn(self, p)
      edit_connection_path(conn)
    end
  end

  ## Message methods

  def received_messages(page = 1)
    _received_messages.paginate(:page => page, :per_page => MESSAGES_PER_PAGE)
  end

  def sent_messages(page = 1)
    _sent_messages.paginate(:page => page, :per_page => MESSAGES_PER_PAGE)
  end

  def trashed_messages(page = 1)
    conditions = [%((sender_id = :dog AND sender_deleted_at > :t) OR
                    (recipient_id = :dog AND recipient_deleted_at > :t)),
                  { :dog => id, :t => TRASH_TIME_AGO }]
    order = 'created_at DESC'
    trashed = Message.paginate(:all, :conditions => conditions,
                                     :order => order,
                                     :page => page,
                                     :per_page => MESSAGES_PER_PAGE)
  end

  def recent_messages
    Message.find(:all,
                 :conditions => [%(recipient_id = ? AND
                                   recipient_deleted_at IS NULL), id],
                 :order => "created_at DESC",
                 :limit => NUM_RECENT_MESSAGES)
  end

  ## Forum helpers
  def forum_posts
    Topic.find(:all,
               :conditions => [%(forum_id =? AND
                                 dog_id = ?), 1, id])
  end

  def has_unread_messages?
    sql = %(recipient_id = :id
            AND sender_id != :id
            AND recipient_deleted_at IS NOT NULL
            AND recipient_read_at IS NULL)
    conditions = [sql, { :id => id }]
    Message.count(:all, :conditions => conditions) > 0
  end

  ## Photo helpers
  
  def photo
    # This should only have one entry, but use 'first' to be paranoid.
    photos.find_all_by_avatar(true).first
  end

  # Return all the photos other than the primary one
  def other_photos
    photos.length > 1 ? photos - [photo] : []
  end

  def main_photo
    photo.nil? ? "default.png" : photo.public_filename
  end

  def thumbnail
    photo.nil? ? "default_thumbnail.png" : photo.public_filename(:thumbnail)
  end

  def icon
    photo.nil? ? "default_icon.png" : photo.public_filename(:icon)
  end

  def bounded_icon
    photo.nil? ? "default_icon.png" : photo.public_filename(:bounded_icon)
  end

  # Return the photos ordered by primary first, then by created_at.
  # They are already ordered by created_at as per the has_many association.
  def sorted_photos
    # The call to partition ensures that the primary photo comes first.
    # photos.partition(&:primary) => [[primary], [other one, another one]]
    # flatten yields [primary, other one, another one]
    @sorted_photos ||= photos.partition(&:primary).flatten
  end

  def active?
    !deactivated? && !owner.deactivated?
  end

  # Return the common connections with the given dog.
  def common_contacts_with(other_person, options = {})
    # I tried to do this in SQL for efficiency, but failed miserably.
    # Horrifyingly, MySQL lacks support for the INTERSECT keyword.
    common_contacts = []
    other_person.dogs.each do |dog|
      common_contacts << (contacts & dog.contacts)
    end
    return common_contacts.flatten.uniq.paginate(options)
  end
  
  protected

    ## Callbacks

    # Handle the case of a nil description.
    # Some databases (e.g., MySQL) don't allow default values for text fields.
    # By default, "blank" fields are really nil, which breaks certain
    # validations; e.g., nil.length raises an exception, which breaks
    # validates_length_of.  Fix this by setting the description to the empty
    # string if it's nil.
    def handle_nil_description
      self.description = "" if description.nil?
    end

    def set_old_description
      @old_description = Dog.find(self).description
    end

    def log_activity_description_changed
      unless @old_description == description or description.blank?
        add_activities(:item => self, :dog => self)
      end
    end
    
    # Clear out all activities associated with this dog.
    def destroy_activities
      Activity.find_all_by_dog_id(self).each {|a| a.destroy}
    end
    
    def destroy_feeds
      Feed.find_all_by_dog_id(self).each {|f| f.destroy}
    end

    ## Other private method(s)
    
    class << self
    
      # Return the conditions for a dog to be active.
      def conditions_for_active
        [%(dogs.deactivated = ? AND people.deactivated = ?),
         false, false]
      end
      
      # Return the conditions for a dog to be 'mostly' active.
      def conditions_for_mostly_active
        [%(dogs.deactivated = ? AND
           people.deactivated = ? AND
           (people.last_logged_in_at IS NOT NULL AND
            people.last_logged_in_at >= ?)),
         false, false, TIME_AGO_FOR_MOSTLY_ACTIVE]
      end
    end  
end
