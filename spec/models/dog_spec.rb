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
      initial_dog.activities.length.should == 5
      dog.destroy
      initial_dog.reload.activities.length.should == 2
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
    
    it "should return person as owner" do
      @dog.person.should == @dog.owner
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
      @contact = dogs(:buba)
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
        @current_user = people(:aaron)
        @max = dogs(:max)
        Connection.connect(@dog, @contact)
        Connection.connect(@max, @contact)
      end

      it "should have common contacts with someone" do
        common_contacts = @dog.common_contacts_with(@current_user)
        common_contacts.size.should == 1
        common_contacts.should be_a_kind_of(WillPaginate::Collection)
        common_contacts.should == [@contact]
      end

      it "should not include non-common contacts" do
        sharik = dogs(:sharik)
        Connection.connect(@dog, sharik)
        @dog.common_contacts_with(@current_user).should_not contain(sharik)
      end

      it "should exclude dogs with deactivated owners from common contacts" do
        @contact.owner.toggle!(:deactivated)
        common_contacts = @dog.common_contacts_with(@current_user)
        common_contacts.should be_empty
      end
      
      it "should exclude the dogs of owner doing the viewing" do
        Connection.connect(@dog, @max)
        @dog.common_contacts_with(@current_user).should_not contain(@max)
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
  
  describe "own group associations" do
    it "should have own groups" do
      @dog.own_groups.should_not be_nil
      @dog.own_groups.should contain(groups(:public))
      dogs(:max).own_groups.should contain(groups(:hidden))
    end
    
    it "should have own not hidden groups" do
      @dog.own_not_hidden_groups.should_not be_nil
      @dog.own_not_hidden_groups.should contain(groups(:public))
      dogs(:max).own_not_hidden_groups.should_not be_nil
      dogs(:max).own_not_hidden_groups.should_not contain(groups(:hidden))
    end
    
    it "should have own hidden groups" do
      @dog.own_hidden_groups.should_not be_nil
      @dog.own_hidden_groups.should be_empty
      dogs(:max).own_hidden_groups.should contain(groups(:hidden))
    end
    
    it "should disappear if the dog is destroyed" do
      Group.find_all_by_dog_id(@dog).should_not be_empty
      @dog.destroy
      Group.find_all_by_dog_id(@dog).should be_empty
    end    
  end
  
  describe "group associations" do
    it "should have membership" do
      @dog.memberships.should_not be_empty
    end
    
    it "should have groups" do
      @dog.groups.should_not be_empty
    end
    
    it "should have not hidden groups" do
      @dog.groups_not_hidden.should_not be_empty
    end
    
    describe "instance methods" do
      it "should have requested memberships" do
        dogs(:dana).requested_memberships.should contain(memberships(:private_buba))
      end
      
      it "should have invitations" do
        dogs(:buba).invitations.should contain(memberships(:public_buba))
      end
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
  
  describe "callback methods" do
    it "should connect the new dog to all other dogs of same owner upon create" do
      new_dog = create_dog
      new_dog.owner.dogs.find(:all, :conditions => ["id <> ?", new_dog.id]).each do |dog|
        Connection.connected?(dog, new_dog).should be_true
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
