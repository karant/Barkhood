require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Event do
  before(:each) do
    @valid_attributes = {
      :title => "value for title",
      :description => "value for description",
      :dog => dogs(:dana),
      :start_time => Time.now,
      :end_time => Time.now,
      :reminder => false,
      :privacy => 1
    }
  end

  it "should create a new instance given valid attributes" do
    Event.unsafe_create!(@valid_attributes)
  end

  describe "privacy settings" do
    before(:each) do
      @dog = dogs(:dana)
      @contact = dogs(:nola)
    end
    it "should find all public events" do
      Event.dog_events(@dog).should include(events(:public))
    end

    it "should find contact's events" do
      @dog.stub!(:contact_ids).and_return([@contact.id])
      Event.dog_events(@dog).should include(events(:private))
    end

    it "should find own events" do
      Event.dog_events(@contact).should include(events(:private))
    end                   
    
    it 'should not find other private events who are not my friends' do
      Event.dog_events(@dog).should_not include(events(:private))
    end
                                       
  end

  describe "attendees association" do
    before(:each) do
      @event = events(:public)
      @dog = dogs(:nola)
    end
    
    it "should allow people to attend" do
      @event.attend(@dog)                                   
      @event.attendees.should include(@dog)
      @event.reload
      @event.event_attendees_count.should be(1)
    end

    it 'should not allow people to attend twice' do
      @event.attend(@dog).should_not be_nil
      @event.attend(@dog).should be_nil
    end
                                        
  end

  describe "comments association" do
    before(:each) do
      @event = events(:public)
    end

    it "should have many comments" do
      @event.comments.should be_a_kind_of(Array)
      @event.comments.should_not be_empty
    end
  end

  describe 'event activity association' do
    before(:each) do
      @event = Event.unsafe_create(@valid_attributes)
      @activity = Activity.find_by_item_id(@event)
    end
    
    it "should have an activity" do
      @activity.should_not be_nil
    end
    
    it "should add an activity to the creator" do
      @event.dog.recent_activity.should contain(@activity)
    end
  end

end
