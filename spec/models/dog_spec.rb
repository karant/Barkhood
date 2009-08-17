require File.dirname(__FILE__) + '/../spec_helper'

describe Dog do

  before(:each) do
    @dog = dogs(:dana)
  end

  describe "attributes" do
    it "should be valid" do
      create_dog.should be_valid
    end

    it "should require name" do
      p = create_dog(:name => nil)
      p.errors.on(:name).should_not be_nil
    end
    
    it "should be valid even with a nil description" do
      p = create_dog(:description => nil)
      p.should be_valid
    end
  end
  
  describe "length validations" do
    it "should enforce a maximum name length" do
      @dog.should have_maximum(:name, Dog::MAX_NAME)
    end
    
    it "should enforce a maximum description length" do
      @dog.should have_maximum(:description, Dog::MAX_DESCRIPTION)
    end
  end

  describe "activity associations" do

    it "should log an activity if description changed" do
      @dog.update_attributes(:description => "New Description")
      activity = Activity.find_by_item_id(@dog)
      Activity.global_feed.should contain(activity)
    end

    it "should not log an activity if description didn't change" do
      @dog.save!
      activity = Activity.find_by_item_id(@dog)
      Activity.global_feed.should_not contain(activity)
    end

    it "should disappear if the dog is destroyed" do
      dog = create_dog(:save => true)
      # Create a feed activity.
      Connection.connect(dog, @dog)
      @dog.update_attributes(:name => "New name")

      Activity.find_all_by_dog_id(dog).should_not be_empty
      dog.destroy
      Activity.find_all_by_dog_id(dog).should be_empty
      Feed.find_all_by_dog_id(dog).should be_empty
    end

    it "should disappear from other feeds if the dog is destroyed" do
      initial_dog = create_dog(:save => true)
      dog         = create_dog(:email => "new@foo.com", :name => "Foo",
                                     :save => true)
      Connection.connect(dog, initial_dog)
      initial_dog.activities.length.should == 1
      dog.destroy
      initial_dog.reload.activities.length.should == 0
    end
  end

  describe "utility methods" do
    it "should have the right to_param method" do
      # Dog params should have the form '1-michael-hartl'.
      param = "#{@dog.id}-dana"
      @dog.to_param.should == param
    end

    it "should have a safe uri" do
      @dog.name = "Michael & Hartl"
      param = "#{@dog.id}-michael-and-hartl"
      @dog.to_param.should == param
    end
  end

  describe "contact associations" do
    it "should have associated photos" do
      @dog.photos.should_not be_nil
    end

    it "should not currently have any photos" do
      @dog.photos.should be_empty
    end

    it "should have an associated blog on creation" do
      dog = create_dog(:save => true)
      dog.blog.should_not be_nil
    end

    it "should have many wall comments" do
      @dog.comments.should be_a_kind_of(Array)
      @dog.comments.should_not be_empty
    end

    it "should not include deactivated users" do
      contact = dogs(:max)
      Connection.connect(@dog, contact)
      @dog.contacts.should contain(contact)
      contact.owner.toggle!(:deactivated)
      @dog.reload.contacts.should_not contain(contact)
    end
    
    it "should not include deactivated dogs" do
      contact = dogs(:deactivated)
      Connection.connect(@dog, contact)
      @dog.reload.contacts.should_not contain(contact)      
    end
  end

  describe "associations" do

    before(:each) do
      @contact = dogs(:max)
    end

    # TODO: make custom matchers to get @contact.should have_requested_contacts
    it "should have requested contacts" do
      Connection.request(@dog, @contact)
      @contact.requested_contacts.should_not be_empty
    end

    it "should have contacts" do
      Connection.connect(@dog, @contact)
      @dog.contacts.should == [@contact]
      @contact.contacts.should == [@dog]
    end

    describe "common contacts" do

      before(:each) do
        @nola = dogs(:nola)
        Connection.connect(@dog, @contact)
        Connection.connect(@nola, @contact)
      end

      it "should have common contacts with someone" do
        common_contacts = @dog.common_contacts_with(@nola)
        common_contacts.size.should == 1
        common_contacts.should be_a_kind_of(WillPaginate::Collection)
        common_contacts.should == [@contact]
      end

      it "should not include non-common contacts" do
        parker = dogs(:parker)
        Connection.connect(@dog, parker)
        @dog.common_contacts_with(@nola).should_not contain(parker)
      end

      it "should exclude dogs with deactivated owners from common contacts" do
        @contact.owner.toggle!(:deactivated)
        common_contacts = @dog.common_contacts_with(@nola)
        common_contacts.should be_empty
      end
      
      it "should exclude the dog being viewed" do
        Connection.connect(@dog, @nola)
        @dog.common_contacts_with(@nola).should_not contain(@nola)
      end
      
      it "should exclude the dog doing the viewing" do
        Connection.connect(@dog, @nola)
        @dog.common_contacts_with(@nola).should_not contain(@dog)
      end
    end
  end

  describe "photo methods" do

    before(:each) do
      @photo_1 = mock_photo(:avatar => true)
      @photo_2 = mock_photo
      @photos = [@photo_1, @photo_2]
      @photos.stub!(:find_all_by_avatar).and_return([@photo_1])
      @dog.stub!(:photos).and_return(@photos)
    end

    it "should have a photo method" do
      @dog.should respond_to(:photo)
    end

    it "should have a non-nil primary photo" do
      @dog.photo.should_not be_nil
    end

    it "should have other photos" do
      @dog.other_photos.should_not be_empty
    end

    it "should have the right other photos" do
      @dog.other_photos.should == (@photos - [@dog.photo])
    end

    it "should have a main photo" do
      @dog.main_photo.should == @dog.photo.public_filename
    end

    it "should have a thumbnail" do
      @dog.thumbnail.should_not be_nil
    end

    it "should have an icon" do
      @dog.icon.should_not be_nil
    end

    it "should have sorted photos" do
      @dog.sorted_photos.should == [@photo_1, @photo_2]
    end
  end

  describe "message associations" do
    it "should have sent messages" do
      @dog.sent_messages.should_not be_nil
    end

    it "should have received messages" do
      @dog.received_messages.should_not be_nil
    end
    
    it "should have unread messages" do
      @dog.has_unread_messages?.should be_true
    end
  end
  
  describe "mostly active" do
    it "should include a recently logged-in dog" do
      Dog.mostly_active.should contain(@dog)
    end
    
    it "should not include a deactivated dog" do
      @dog.toggle!(:deactivated)
      Dog.mostly_active.should_not contain(@dog)
    end
    
    it "should not include dogs with deactivated owner" do
      @dog.owner.toggle!(:deactivated)
      Dog.mostly_active.should_not contain(@dog)
    end
    
    it "should not include a dog with an owner who has never logged in" do
      @dog.owner.update_attribute(:last_logged_in_at, nil)
      Dog.mostly_active.should_not contain(@dog)
    end
    
    it "should not include an dog with an owner who logged in too long ago" do
      @dog.owner.update_attribute(:last_logged_in_at, (Dog::TIME_AGO_FOR_MOSTLY_ACTIVE - 1))
      Dog.mostly_active.should_not contain(@dog)
    end
  end
  
  describe "active class methods" do
    it "should not return deactivated dogs" do
      @dog.toggle!(:deactivated)
      [:active, :all_active].each do |method|
        Dog.send(method).should_not contain(@dog)
      end
    end
    
    it "should not return dogs with deactivated owners" do
      @dog.owner.toggle!(:deactivated)
      [:active, :all_active].each do |method|
        Dog.send(method).should_not contain(@dog)
      end
    end
  end
    
  protected

    def create_dog(options = {})
      record = people(:quentin).dogs.build({ :name => 'Kashtanka', :description => 'A new dog', :breed => breeds(:german_pointer), 
                                             :dob => 2.years.ago, :sex => 'Female' }.merge(options))
      record.valid?
      record.save! if options[:save]
      record
    end
end
