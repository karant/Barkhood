require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Group do
  before(:each) do
    @group = groups(:public)
    @private_group = groups(:private)
    @hidden_group = groups(:hidden)
  end

  describe "attributes" do
    it "should be valid" do
      create_group.should be_valid
    end

    it "should require name" do
      p = create_group(:name => nil)
      p.errors.on(:name).should_not be_nil
    end
    
    it "should be valid even with a nil description" do
      p = create_group(:description => nil)
      p.should be_valid
    end
  end
  
  describe "callbacks" do
    it "should create membership for owner upon group create" do
      g = create_group(:save => true)
      g.dogs.should contain(g.owner)
    end
  end  
  
  describe "length validations" do
    it "should enforce a maximum name length" do
      @group.should have_maximum(:name, Group::MAX_NAME)
    end
    
    it "should enforce a maximum description length" do
      @group.should have_maximum(:description, Group::MAX_DESCRIPTION)
    end
  end

  describe "activity associations" do

#    it "should log an activity if description changed" do
#      @group.update_attributes(:description => "New Description")
#      activity = Activity.find_by_item_id(@group)
#      Activity.global_feed.should contain(activity)
#    end
#
#    it "should not log an activity if description didn't change" do
#      @group.save!
#      activity = Activity.find_by_item_id(@group)
#      Activity.global_feed.should_not contain(activity)
#    end

# TODO : need activity to be polymorphic for this to work
#    it "should disappear if the group is destroyed" do
#      group = create_group(:save => true)
#      group.update_attributes(:name => "New name")
#
#      Activity.find_all_by_dog_id(group.owner).should_not be_empty
#      group.destroy
#      Activity.find_all_by_dog_id(group.owner).should be_empty
#      Feed.find_all_by_dog_id(group.owner).should be_empty
#    end

    it "should log an activity when the group is created" do
      lambda do
        group = create_group(:save => true)
      end.should change(Activity, :count).by(2)
    end
  end

  describe "utility methods" do
    it "should have the right to_param method" do
      # Dog params should have the form '1-michael-hartl'.
      param = "#{@group.id}-public"
      @group.to_param.should == param
    end

    it "should have a safe uri" do
      @group.name = "Michael & Hartl"
      param = "#{@group.id}-michael-and-hartl"
      @group.to_param.should == param
    end
    
    it "should identify public groups" do
      @group.public?.should == true
      @private_group.public?.should == false
    end
    
    it "should identify private groups" do
      @private_group.private?.should == true
      @group.private?.should == false
    end
    
    it "should identify hidden groups" do
      @hidden_group.hidden?.should == true
      @group.hidden?.should == false
    end
    
    it "should check if the person is the owner of the group" do
      @group.owner?(people(:quentin)).should == true
      @group.owner?(people(:aaron)).should == false
    end
    
    it "should identify people with invited dogs" do
      @group.has_invited?(dogs(:buba)).should == true
      @group.has_invited?(dogs(:dana)).should == false
    end
    
    it "should return owner's owner as person" do
      @group.person.should == @group.owner.owner
    end
  end

  describe "associations" do

    before(:each) do
      @member = dogs(:max)
    end
    
    describe "memberships" do
      it "should have memberships" do
        @group.memberships.should_not be_nil
      end
      
      describe "accepted" do
        it "should have dogs" do
          @group.dogs.should contain(dogs(:nola))
        end
        
        it "should exclude dogs with inactive owners" do
          member = dogs(:nola)
          @group.dogs.should contain(member)
          member.owner.toggle!(:deactivated)
          @group.reload.dogs.should_not contain(member)          
        end
        
        it "should exclude deactivated dogs" do
          member = dogs(:nola)
          @group.dogs.should contain(member)
          member.toggle!(:deactivated)
          @group.reload.dogs.should_not contain(member)  
        end
      end
      
      describe "pending requests" do
        it "should have pending membership requests" do
          @private_group.pending_requests.should contain(dogs(:buba))
        end
        
        it "should exclude dogs with inactive owners" do
          member = dogs(:buba)
          @private_group.pending_requests.should contain(member)
          member.owner.toggle!(:deactivated)
          @private_group.reload.pending_requests.should_not contain(member)          
        end
        
        it "should exclude deactivated dogs" do
          member = dogs(:buba)
          @private_group.pending_requests.should contain(member)
          member.toggle!(:deactivated)
          @private_group.reload.pending_requests.should_not contain(member)  
        end        
      end

      describe "pending invitations" do
        it "should have pending membership invitations" do
          @hidden_group.pending_invitations.should contain(dogs(:dana))
        end   
        
        it "should exclude dogs with inactive owners" do
          member = dogs(:dana)
          @hidden_group.pending_invitations.should contain(member)
          member.owner.toggle!(:deactivated)
          @hidden_group.reload.pending_invitations.should_not contain(member)          
        end
        
        it "should exclude deactivated dogs" do
          member = dogs(:dana)
          @hidden_group.pending_invitations.should contain(member)
          member.toggle!(:deactivated)
          @hidden_group.reload.pending_invitations.should_not contain(member)  
        end         
      end
    end
    
    it "should have associated photos" do
      @group.photos.should_not be_nil
    end

    it "should not currently have any photos" do
      @group.photos.should be_empty
    end

    it "should have an associated blog on creation" do
      group = create_group(:save => true)
      group.blog.should_not be_nil
    end

    it "should have many wall comments" do
      @group.comments.should be_a_kind_of(Array)
      @group.comments.should_not be_empty
    end  
    
    it "should have many people" do
      @group.people.should_not be_nil
    end
    
    it "should have an owner" do
      @group.owner.should == dogs(:dana)
    end
    
    it "should have associated galleries" do
      @group.galleries.should_not be_nil
    end
    
    it "should have associated events" do
      @private_group.events.should_not be_nil
      @private_group.events.should be_a_kind_of(Array)
    end
  end
  
  describe "photo methods" do

    before(:each) do
      @photo_1 = mock_photo(:avatar => true)
      @photo_2 = mock_photo
      @photos = [@photo_1, @photo_2]
      @photos.stub!(:find_all_by_avatar).and_return([@photo_1])
      @group.stub!(:photos).and_return(@photos)
    end

    it "should have a photo method" do
      @group.should respond_to(:photo)
    end

    it "should have a non-nil primary photo" do
      @group.photo.should_not be_nil
    end

    it "should have other photos" do
      @group.other_photos.should_not be_empty
    end

    it "should have the right other photos" do
      @group.other_photos.should == (@photos - [@group.photo])
    end

    it "should have a main photo" do
      @group.main_photo.should == @group.photo.public_filename
    end

    it "should have a thumbnail" do
      @group.thumbnail.should_not be_nil
    end

    it "should have an icon" do
      @group.icon.should_not be_nil
    end

    it "should have sorted photos" do
      @group.sorted_photos.should == [@photo_1, @photo_2]
    end
  end
  
  describe "class methods" do
    it "should not return hidden groups" do
      Group.not_hidden.should_not contain(@hidden_group)
    end
    
    it "should return public groups" do
      Group.not_hidden.should contain(@group)
    end
    
    it "should return private groups" do
      Group.not_hidden.should contain(@private_group)
    end
  end
    
  protected

    def create_group(options = {})
      record = dogs(:dana).groups.build({ :name => 'Group', :description => 'A new group', :mode => 0 }.merge(options))
      record.valid?
      record.save! if options[:save]
      record
    end
end
