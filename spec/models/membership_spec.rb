require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Membership do
  
  before(:each) do
    @emails = ActionMailer::Base.deliveries
    @emails.clear
    @global_prefs = Preference.find(:first)
    
    @dog = dogs(:parker)
    @group = groups(:public)
    @private_group = groups(:private)
  end

  describe "class methods" do

    it "should create and accept a membership request for public group" do
      Membership.request(@dog, @group)
      status(@dog, @group).should == Membership::ACCEPTED
    end
    
    it "should create a membership request for private group" do
      Membership.request(@dog, @private_group)
      status(@dog, @private_group).should == Membership::PENDING
    end
    
    it "should create a membership invitation for public group" do
      Membership.invite(@dog, @group)
      status(@dog, @group).should == Membership::INVITED
    end
  
    it "should send an email when global/contact notifications are on" do
      # Both notifications are on by default.
      lambda do
        Membership.request(@dog, @group)
      end.should change(@emails, :length).by(2)
    end
    
    it "should not send an email when person's notifications are off" do
      @group.owner.owner.toggle!(:connection_notifications)
      @dog.owner.connection_notifications.should == false
      lambda do
        Membership.request(@dog, @group)
      end.should_not change(@emails, :length)
    end
    
    it "should not send an email when global notifications are off" do
      @global_prefs.update_attributes(:email_notifications => false)
      lambda do
        Membership.request(@dog, @group)
      end.should_not change(@emails, :length)
    end
    
    it "should determine if dog has membership in a group" do
      Membership.exists?(dogs(:dana), @group).should == true
      Membership.exists?(@dog, @group).should == false
    end
    
    it "should determine if dog has accepted membership in a group" do
      Membership.accepted?(dogs(:dana), @group).should == true
      Membership.accepted?(@dog, @group).should == false
    end
    
    it "should determine if person has accepted membership in a group" do
      Membership.accepted_by_person?(people(:quentin), @group).should == true
      Membership.accepted_by_person?(@dog.owner, @group).should == false
    end
    
    it "should determine if dog has pending requests to join a group" do
      other_dog = dogs(:buba)
      Membership.pending?(other_dog, @private_group).should == true
      Membership.pending?(@dog, @private_group).should == false      
    end
    
    it "should determine if the dog has pending invitations to join a group" do
      other_dog = dogs(:buba)
      Membership.invited?(other_dog, @group).should == true
      Membership.invited?(@dog, @group).should == false      
    end
    
    it "shoud determine if any of person's dogs have pending invitations to join a group" do
      other_dog = dogs(:buba)
      Membership.invited_person?(other_dog.owner, @group).should == true
      Membership.invited_person?(@dog.owner, @group).should == false
    end
    
    it "should accept a request" do
      Membership.request(@dog, @private_group)
      Membership.accept(@dog,  @private_group)
      status(@dog, @private_group).should == Membership::ACCEPTED
    end
    
    it "should accept an invitation" do
      Membership.invite(@dog, @group)
      Membership.accept(@dog, @group)
      status(@dog, @group).should == Membership::ACCEPTED
    end
  
    it "should break up a request" do
      Membership.request(@dog, @group)
      Membership.breakup(@dog, @group)
      Membership.exists?(@dog, @group).should be_false
    end
  end
  
  describe "instance methods" do
    
    before(:each) do
      Membership.request(@dog, @private_group)
      @membership = Membership.mem(@dog, @private_group)
    end
    
    it "should accept a request" do
      @membership.accept
    end
    
    it "should break up a connection" do
      @membership.breakup
      Membership.exists?(@dog, @private_group).should be_false
    end
  end
  
  
  it "should create a feed activity for a new membership" do
    Membership.request(@dog, @group)
    membership = Membership.mem(@dog, @group)
    membership.accept
    activity = Activity.find_by_item_id(membership)
    activity.should_not be_nil
    activity.dog.should_not be_nil
  end
  
  def status(dog, group)
    Membership.mem(dog, group).status
  end
end
