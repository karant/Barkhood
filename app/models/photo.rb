class Photo < ActiveRecord::Base
  include ActivityLogger
  UPLOAD_LIMIT = 5 # megabytes
  
  # attr_accessible is a nightmare with attachment_fu, so use
  # attr_protected instead.
  attr_protected :id, :dog_id, :parent_id, :created_at, :updated_at
  
  belongs_to :dog
  has_attachment :content_type => :image,
                 :storage => :file_system,
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
  validates_presence_of :dog_id
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
      activity = Activity.create!(:item => self, :dog => dog)
      add_activities(:activity => activity, :dog => dog)
  end

end
