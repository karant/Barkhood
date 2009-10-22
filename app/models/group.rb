class Group < ActiveRecord::Base
  include ActivityLogger
  
  attr_accessible :name, :description, :mode
  
  validates_presence_of :name, :dog_id
  
  NUM_WALL_COMMENTS = 10
  MAX_NAME = 40
  MAX_DESCRIPTION = 5000
  
  ACCEPTED_AND_ACTIVE =  [%(memberships.status = ? AND
                            dogs.deactivated = ? AND
                            people.deactivated = ?),
                          Membership::ACCEPTED, false, false]         
  INVITED_AND_ACTIVE =   [%(memberships.status = ? AND
                            dogs.deactivated = ? AND
                            people.deactivated = ?),
                          Membership::INVITED, false, false]                     
  PENDING_AND_ACTIVE =   [%(memberships.status = ? AND
                            dogs.deactivated = ? AND
                            people.deactivated = ?),
                          Membership::PENDING, false, false]                           
  
  has_one :blog, :as => :owner
  has_many :memberships, :dependent => :destroy
  has_many :dogs, :through => :memberships, :include => [:owner],
    :conditions => ACCEPTED_AND_ACTIVE, :order => "dogs.name ASC"
  has_many :pending_requests, :through => :memberships, :source => "dog", :include => [:owner],
    :conditions => PENDING_AND_ACTIVE, :order => "dogs.name DESC"
  has_many :pending_invitations, :through => :memberships, :source => "dog", :include => [:owner],
    :conditions => INVITED_AND_ACTIVE, :order => "dogs.name DESC"
  has_many :events
#  has_many :people, :through => :dogs, :source => 'owner'
  
  belongs_to :owner, :class_name => "Dog", :foreign_key => "dog_id"
  
#  has_many :activities, :as => :owner, :conditions => ["owner_type = ?","Group"],
#    :foreign_key => "item_id", :dependent => :destroy
  
  has_many :galleries, :as => :owner, :dependent => :destroy
  has_many :photos, :through => :galleries, :order => "created_at"  
  
  has_many :comments, :as => :commentable, :order => 'created_at DESC',
                      :limit => NUM_WALL_COMMENTS, :dependent => :destroy

  validates_length_of       :name,  :maximum => MAX_NAME
  validates_length_of       :description, :maximum => MAX_DESCRIPTION
  
  before_create :create_blog
  before_validation :handle_nil_description
  after_create :log_activity, :create_owner_membership
#  before_update :set_old_description
#  after_update :log_activity_description_changed
  
  is_indexed :fields => [ 'name', 'description']
  
  # GROUP modes
  PUBLIC = 0
  PRIVATE = 1
  HIDDEN = 2
  
  class << self
 
    # Return not hidden groups
    def not_hidden(page = 1)
      paginate(:all, :page => page,
                     :per_page => RASTER_PER_PAGE,
                     :conditions => ["mode = ? OR mode = ?", PUBLIC,PRIVATE],
                     :order => "name ASC")
    end
  end
  
  def person
    owner.owner
  end
  
  # Couldn't get it done through associations (has_many :people, :through => :dogs, :as => 'owner')
  def people
    Person.find(dogs.map(&:owner_id))
  end
  # Params for use in urls.
  # Profile urls have the form '/groups/1-public'.
  # This works automagically because Group.find(params[:id]) implicitly
  # converts params[:id] into an int, and in Ruby
  # '1-dana'.to_i == 1
  def to_param
    "#{id}-#{name.to_safe_uri rescue nil}"
  end  

  # TODO - Need to make activity polymorphic for this to work
#  def recent_activity
#    Activity.find_all_by_owner_id(self, :order => 'created_at DESC',
#                                        :conditions => "owner_type = 'Group'",
#                                         :limit => 10)
#  end
  
  def public?
    self.mode == PUBLIC
  end
  
  def private?
    self.mode == PRIVATE
  end
  
  def hidden?
    self.mode == HIDDEN
  end
  
  def owner?(person)
    self.owner.owner == person
  end
  
  def has_invited?(dog)
    Membership.invited?(dog,self)
  end
  
  ## Photo helpers
  def photo
    # This should only have one entry, but be paranoid.
    photos.find_all_by_avatar(true).first
  end
 
  # Return all the photos other than the primary one
  def other_photos
    photos.length > 1 ? photos - [photo] : []
  end
 
  def main_photo
    photo.nil? ? "g_default.png" : photo.public_filename
  end
 
  def thumbnail
    photo.nil? ? "g_default_thumbnail.png" : photo.public_filename(:thumbnail)
  end
 
  def icon
    photo.nil? ? "g_default_icon.png" : photo.public_filename(:icon)
  end
 
  def bounded_icon
    photo.nil? ? "g_default_icon.png" : photo.public_filename(:bounded_icon)
  end
 
  # Return the photos ordered by primary first, then by created_at.
  # They are already ordered by created_at as per the has_many association.
  def sorted_photos
    # The call to partition ensures that the primary photo comes first.
    # photos.partition(&:primary) => [[primary], [other one, another one]]
    # flatten yields [primary, other one, another one]
    @sorted_photos ||= photos.partition(&:primary).flatten
  end
  
  
  private
  
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
      @old_description = Group.find(self).description
    end
   
    def log_activity_description_changed
      unless @old_description == description or description.blank?
        add_activities(:item => self, :dog => self.owner)
      end
    end
    
    def log_activity
      if not self.hidden?
        activity = Activity.create!(:item => self, :dog => self.owner)
        add_activities(:activity => activity, :dog => self.owner)
      end
  end
  
  def create_owner_membership
    Membership.request(owner, self, false)
    unless mode == PUBLIC
      Membership.accept(owner, self)
    end
  end
end
