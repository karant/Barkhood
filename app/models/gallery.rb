class Gallery < ActiveRecord::Base
  include ActivityLogger
  
  attr_accessible :title, :description
  
  belongs_to :dog
  has_many :photos, :dependent => :destroy, :order => :position
  has_many :activities, :foreign_key => "item_id", :dependent => :destroy,
                        :conditions => "item_type = 'Gallery'"
  

  validates_length_of :title, :maximum => 255, :allow_nil => true
  validates_length_of :description, :maximum => 1000, :allow_nil => true
  validates_presence_of :dog_id

  before_create :handle_nil_description
  after_create :log_activity
  
  def self.per_page
    5
  end
  

  def primary_photo
    photos.find_all_by_primary(true).first
  end
  
  def primary_photo=(photo)
    if photo.nil?
      self.primary_photo_id = nil
    else
      self.primary_photo_id = photo.id
    end
  end
  
  def primary_photo_url
    primary_photo.nil? ? "default.png" : primary_photo.public_filename
  end

  def thumbnail_url
    primary_photo.nil? ? "default_thumbnail.png" :
                          primary_photo.public_filename(:thumbnail)
  end

  def icon_url
    primary_photo.nil? ? "default_icon.png" :
                         primary_photo.public_filename(:icon)
  end

  def bounded_icon_url
    primary_photo.nil? ? "default_icon.png" :
                         primary_photo.public_filename(:bounded_icon)
  end
    
  def short_description
    description[0..124]
  end

  protected

    def handle_nil_description
      self.description = "" if description.nil?
    end

    def log_activity
      activity = Activity.create!(:item => self, :dog => dog)
      add_activities(:activity => activity, :dog => dog)
    end
end
