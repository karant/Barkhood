class Activity < ActiveRecord::Base
  belongs_to :dog
  belongs_to :item, :polymorphic => true
  has_many :feeds, :dependent => :destroy
  
  GLOBAL_FEED_SIZE = 10

  # Return a feed drawn from all activities.
  # The fancy SQL is to keep inactive dogs out of feeds.
  # It's hard to do that entirely, but this way deactivated dogs 
  # won't be the dog in "<dog> has <done something>".
  def self.global_feed
    find(:all, 
         :joins => "INNER JOIN dogs d ON activities.dog_id = d.id",
         :conditions => [%(d.deactivated = ?), 
                         false], 
         :order => 'activities.created_at DESC',
         :limit => GLOBAL_FEED_SIZE)
  end
end
