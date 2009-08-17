class EventAttendee < ActiveRecord::Base
  include ActivityLogger

  belongs_to :dog
  belongs_to :event, :counter_cache => true
  validates_uniqueness_of :dog_id, :scope => :event_id

  after_create :log_activity

  def log_activity
    add_activities(:item => self, :dog => self.dog)
  end

end
