class Photo < ActiveRecord::Base
  include ActivityLogger
  UPLOAD_LIMIT = 5 # megabytes
  
  # attr_accessible is a nightmare with attachment_fu, so use
  # attr_protected instead.
  attr_protected :id, :created_by_id, :parent_id, :created_at, :updated_at
  
  belongs_to :created_by, :class_name => 'Person', :foreign_key => 'created_by_id'
  has_attachment :content_type => :image,
                 :storage => :s3,
                 :max_size => UPLOAD_LIMIT.megabytes,
                 :min_size => 1,
                 :resize_to => '240>',
                 :thumbnails => { :thumbnail    => '72>',
                                  :icon         => '36>',
                                  :bounded_icon => '36x36>' },
                 :thumbnail_class => Thumbnail

  belongs_to :gallery, :counter_cache => true
  acts_as_list :scope => :gallery_id  
  has_many :activities, :foreign_key => "item_id",
                        :conditions => "item_type = 'Photo'",
                        :dependent => :destroy
    
  validates_length_of :title, :maximum => 255, :allow_nil => true
  validates_presence_of :created_by_id
  validates_presence_of :gallery_id
  
  after_create :log_activity
  
  def self.per_page
    16
  end
                 
  # Override the crappy default AttachmentFu error messages.
  def validate
    if filename.nil?
      errors.add_to_base("You must choose a file to upload")
    else
      # Images should only be GIF, JPEG, or PNG
      enum = attachment_options[:content_type]
      unless enum.nil? || enum.include?(send(:content_type))
        errors.add_to_base("You can only upload images (GIF, JPEG, or PNG)")
      end
      # Images should be less than UPLOAD_LIMIT MB.
      enum = attachment_options[:size]
      unless enum.nil? || enum.include?(send(:size))
        msg = "Images should be smaller than #{UPLOAD_LIMIT} MB"
        errors.add_to_base(msg)
      end
    end
  end
  
  def label
    title.nil? ? "" : title
  end

  def label_from_filename
    File.basename(filename, File.extname(filename)).titleize
  end
  
  def log_activity
      case gallery.owner.class.to_s
        when 'Group'
          activity_dog = nil
          created_by.dogs.each do |dog|
            if Membership.accepted?(dog, gallery.owner)
              activity_dog = dog
              break
            end
          end
          activity_dog = gallery.owner.owner unless activity_dog
        when 'Dog'
          activity_dog = gallery.owner
      end
      activity = Activity.create!(:item => self, :dog => activity_dog)
      add_activities(:activity => activity, :dog => activity_dog)
  end
  
  def base_path(thumbnail = nil)
    file_system_path = (thumbnail.blank? ? self : thumbnail_class).attachment_options[:path_prefix].to_s
    File.join(file_system_path, attachment_path_id)
  end
      
  def full_filename(thumbnail = nil)
    File.join(base_path(thumbnail), thumbnail_name_for(thumbnail))
  end  
end
