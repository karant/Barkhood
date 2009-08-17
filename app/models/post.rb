class Post < ActiveRecord::Base
  include ActivityLogger
  belongs_to :dog
  has_many :activities, :foreign_key => "item_id", :dependent => :destroy,
                        :conditions => "item_type = 'Post'"
  attr_accessible nil
end
