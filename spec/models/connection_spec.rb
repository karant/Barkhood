require File.dirname(__FILE__) + '/../spec_helper'

describe Connection do
  
  before(:each) do
    @emails = ActionMailer::Base.deliveries
    @emails.clear
    @global_prefs = Preference.find(:first)
    
    @dog = dogs(:dana)
    @contact = dogs(:max)
  end

  describe "class methods" do

    it "should create a request" do
      Connection.request(@dog, @contact)
      status(@dog, @contact).should == Connection::PENDING
      status(@contact, @dog).should == Connection::REQUESTED
    end
  
    it "should send an email when global/contact notifications are on" do
      # Both notifications are on by default.
      lambda do
        Connection.request(@dog, @contact)
      end.should change(@emails, :length).by(1)
    end
    
    it "should not send an email when contact's notifications are off" do
      @contact.owner.toggle!(:connection_notifications)
      @contact.owner.connection_notifications.should == false
      lambda do
        Connection.request(@dog, @contact)
      end.should_not change(@emails, :length)
    end
    
    it "should not send an email when global notifications are off" do
      @global_prefs.update_attributes(:email_notifications => false)
      lambda do
        Connection.request(@dog, @contact)
      end.should_not change(@emails, :length)
    end
    
    it "should determine if dog has connections (active or pending) to any of person's dogs" do
      Connection.request(@dog, @contact)
      Connection.exists_with_person?(@dog, people(:aaron)).should == true
      Connection.exists_with_person?(@dog, people(:kelly)).should == false
    end
    
    it "should determine if dog has active connections to any of person's dogs" do
      Connection.connect(@dog, @contact)
      Connection.request(@dog, dogs(:buba))
      Connection.connected_with_person?(@dog, people(:aaron)).should == true
      Connection.connected_with_person?(@dog, people(:kelly)).should == false
    end
    
    it "should determine if any of person's dogs have pending connections requested by the viewed dog" do
      Connection.request(@dog, @contact)
      Connection.pending_with_dog?(people(:aaron), @dog).should == true
      Connection.pending_with_dog?(people(:kelly), @dog).should == false      
    end
    
    it "should determine if the viewed dog has pending connections requested by the person" do
      Connection.request(@dog, @contact)
      Connection.pending_with_person?(@contact, people(:quentin)).should == true
      Connection.pending_with_person?(@contact, people(:kelly)).should == false      
    end
    
    describe "connect method" do
      it "should not send an email when contact's notifications are off" do
        @contact.owner.toggle!(:connection_notifications)
        @contact.owner.connection_notifications.should == false
        lambda do
          Connection.connect(@dog, @contact)
        end.should_not change(@emails, :length)
      end
    end
    
    it "should accept a request" do
      Connection.request(@dog, @contact)
      Connection.accept(@dog,  @contact)
      status(@dog, @contact).should == Connection::ACCEPTED
      status(@contact, @dog).should == Connection::ACCEPTED
    end
  
    it "should break up a connection" do
      Connection.request(@dog, @contact)
      Connection.breakup(@dog, @contact)
      Connection.exists?(@dog, @contact).should be_false
    end
  end
  
  describe "instance methods" do
    
    before(:each) do
      Connection.request(@dog, @contact)
      @connection = Connection.conn(@dog, @contact)
    end
    
    it "should accept a request" do
      @connection.accept
    end
    
    it "should break up a connection" do
      @connection.breakup
      Connection.exists?(@dog, @contact).should be_false
    end
  end
  
  
  it "should create a feed activity for a new connection" do
    connection = Connection.connect(@dog, @contact)
    activity = Activity.find_by_item_id(connection)
    activity.should_not be_nil
    activity.dog.should_not be_nil
  end
  
  def status(dog, conn)
    Connection.conn(dog, conn).status
  end
end
