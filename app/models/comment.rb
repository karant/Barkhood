# == Schema Information
# Schema version: 20080916002106
#
# Table name: comments
#
#  id               :integer(4)      not null, primary key
#  commenter_id     :integer(4)      
#  commentable_id   :integer(4)      
#  commentable_type :string(255)     default(""), not null
#  body             :text            
#  created_at       :datetime        
#  updated_at       :datetime        
#

class Comment < ActiveRecord::Base
  include ActivityLogger
  extend PreferencesHelper
  
  attr_accessor :commented_dog, :send_mail

  attr_accessible :body
  
  belongs_to :commentable, :polymorphic => true
  belongs_to :commenter, :class_name => "Dog",
                         :foreign_key => "commenter_id"

  belongs_to :dog, :counter_cache => true
  belongs_to :post
  belongs_to :event

  has_many :activities, :foreign_key => "item_id",
                        :conditions => "item_type = 'Comment'",
                        :dependent => :destroy

  validates_presence_of :body, :commenter
  validates_length_of :body, :maximum => MAX_TEXT_LENGTH
  validates_length_of :body, :maximum => MEDIUM_TEXT_LENGTH,
                             :if => :wall_comment?
  
  after_create :log_activity, :send_receipt_reminder
    
  # Return the dog for the thing commented on.
  # For example, for blog post comments it's the blog's dog
  # For wall comments, it's the dog.
  def commented_dog
    @commented_dog ||= case commentable.class.to_s
                         when "Dog"
                           commentable
                         when "BlogPost"
                           commentable.blog.dog
                         when "Event"
                           commentable.dog
                         end
  end
  
  private
    
    def wall_comment?
      commentable.class.to_s == "Dog"
    end
  
    def blog_post_comment?
      commentable.class.to_s == "BlogPost"
    end

    def event_comment?
      commentable.class.to_s == "Event"
    end
    
    def notifications?
      if wall_comment?
        commented_dog.wall_comment_notifications?
      elsif blog_post_comment?
        commented_dog.blog_comment_notifications?
      end
    end
  
    def log_activity
      activity = Activity.create!(:item => self, :dog => commenter)
      add_activities(:activity => activity, :dog => commenter)
      unless commented_dog.nil? or commenter == commented_dog
        add_activities(:activity => activity, :dog => commented_dog,
                       :include_dog => true)
      end
    end
    
    def send_receipt_reminder
      return if commenter == commented_dog
      if wall_comment?
        @send_mail ||= Comment.global_prefs.email_notifications? &&
                       commented_dog.owner.wall_comment_notifications?
        PersonMailer.deliver_wall_comment_notification(self) if @send_mail
      elsif blog_post_comment?
        @send_mail ||= Comment.global_prefs.email_notifications? &&
                       commented_dog.owner.blog_comment_notifications?
        PersonMailer.deliver_blog_comment_notification(self) if @send_mail
      end
    end
end
