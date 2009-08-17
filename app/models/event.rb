class Event < ActiveRecord::Base
  include ActivityLogger

  attr_accessible :title, :description

  MAX_DESCRIPTION_LENGTH = MAX_STRING_LENGTH
  MAX_TITLE_LENGTH = 40
  PRIVACY = { :public => 1, :contacts => 2 }

  belongs_to :dog
  has_many :event_attendees
  has_many :attendees, :through => :event_attendees, :source => :dog
  has_many :comments, :as => :commentable, :order => 'created_at DESC'
  has_many :activities, :foreign_key => "item_id", :dependent => :destroy,
                        :conditions => "item_type = 'Event'"
  

  validates_presence_of :title, :start_time, :dog, :privacy
  validates_length_of :title, :maximum => MAX_TITLE_LENGTH
  validates_length_of :description, :maximum => MAX_DESCRIPTION_LENGTH, :allow_blank => true

  named_scope :dog_events, 
              lambda { |dog| { :conditions => ["dog_id = ? OR (privacy = ? OR (privacy = ? AND (dog_id IN (?))))", 
                                                  dog.id,
                                                  PRIVACY[:public], 
                                                  PRIVACY[:contacts], 
                                                  dog.contact_ids] } }

  named_scope :period_events,
              lambda { |date_from, date_until| { :conditions => ['start_time >= ? and start_time <= ?',
                                                 date_from, date_until] } }

  after_create :log_activity
  
  def self.monthly_events(date)
    self.period_events(date.beginning_of_month, date.to_time.end_of_month)
  end
  
  def self.daily_events(date)
    self.period_events(date.beginning_of_day, date.to_time.end_of_day)
  end

  def validate
    if end_time
      unless start_time <= end_time
        errors.add(:start_time, "can't be later than End Time")
      end
    end
  end
  
  def attend(dog)
    self.event_attendees.create!(:dog => dog)
  rescue ActiveRecord::RecordInvalid
    nil
  end

  def unattend(dog)
    if event_attendee = self.event_attendees.find_by_dog_id(dog)
        event_attendee.destroy
    else
      nil
    end
  end

  def attending?(dog)
    self.attendee_ids.include?(dog[:id])
  end

  def only_contacts?
    self.privacy == PRIVACY[:contacts]
  end

  private

    def log_activity
      add_activities(:item => self, :dog => self.dog)
    end

end
