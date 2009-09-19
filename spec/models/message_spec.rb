require File.dirname(__FILE__) + '/../spec_helper'

describe Message do
  
  before(:each) do
    @sender    = dogs(:dana)
    @recipient = dogs(:max)
    @message   = new_message
  end
  
  it "should be valid" do
    @message.should be_valid
  end
  
  it "should have the right sender" do
    @message.sender.should == @sender
  end
  
  it "should have the right recipient" do
    @message.recipient.should == @recipient
  end
  
  it "should require a subject" do
    new_message(:subject => "").should_not be_valid
  end
  
  it "should require content" do
    new_message(:content => "").should_not be_valid
  end
  
  it "should not be too long" do
    too_long_content = "a" * (Message::MAX_CONTENT_LENGTH + 1)
    new_message(:content => too_long_content).should_not be_valid
  end

  it "should be able to trash messages as sender" do
    @message.trash(@message.sender.owner)
    @message.should be_trashed(@message.sender.owner)
    @message.should_not be_trashed(@message.recipient.owner)
  end
  
  it "should be able to trash message as recipient" do
    @message.trash(@message.recipient.owner)
    @message.should be_trashed(@message.recipient.owner) 
    @message.should_not be_trashed(@message.sender.owner)
  end
  
  it "should description not be able to trash as another dog" do
    buba = dogs(:buba)
    buba.should_not == @message.sender
    buba.should_not == @message.recipient
    lambda { @message.trash(buba.owner) }.should raise_error(ArgumentError)
  end
  
  it "should untrash messages" do
    @message.trash(@message.sender.owner)
    @message.should be_trashed(@message.sender.owner)
    @message.untrash(@message.sender.owner)
    @message.should_not be_trashed(@message.sender.owner)
  end
  
  it "should handle replies" do
    @message.save!
    @reply = create_message(:sender    => @message.recipient,
                            :recipient => @message.sender,
                            :parent    => @message)
    @reply.should be_reply
    @reply.parent.should be_replied_to
  end

  it "should not allow anyone but recipient to reply" do
    @message.save!
    @next_message = create_message(:sender    => dogs(:parker),
                                   :recipient => @message.sender,
                                   :parent    => @message)
    @next_message.should_not be_reply
    @next_message.parent.should_not be_replied_to
  end
  
  it "should mark messages as read" do
    @message.mark_as_read
    @message.should be_read
  end
  
  it "should belong to a conversation" do
    @message.should respond_to(:conversation)
  end

  it "should assign conversation ids properly" do
    @message.save!
    @message.conversation.should_not be_nil
    @next_message = create_message(:sender    => dogs(:parker),
                                   :recipient => @message.sender,
                                   :parent    => @message)
    @next_message.conversation.should == @message.conversation
  end
    
  describe "email notifications" do
    
    before(:each) do
      @emails = ActionMailer::Base.deliveries
      @emails.clear
      @global_prefs = Preference.find(:first)
    end
    
    it "should send an email when global/recipient notifications are on" do
      # Both notifications are on by default.
      lambda do
        @message.save
      end.should change(@emails, :length).by(1)
    end
    
    it "should not send an email when recipient's notifications are off" do
      @recipient.owner.toggle!(:message_notifications)
      @recipient.owner.message_notifications.should == false
      lambda do
        @message.save
      end.should_not change(@emails, :length)
    end
    
    it "should not send an email when global notifications are off" do
      @global_prefs.update_attributes(:email_notifications => false)
      lambda do
        @message.save
      end.should_not change(@emails, :length)
    end
      
      it "should not send an email for an own-message" do
        lambda do
          create_message(:sender => @sender, :recipient => @sender)
        end.should_not change(@emails, :length)
      end
  end


  private

    def new_message(options = { :sender => @sender, :recipient => @recipient })
      Message.unsafe_build({ :subject => "The subject",
                             :content => "Lorem ipsum" }.merge(options))
    end
  
    def create_message(options = { :sender => @sender,
                                   :recipient => @recipient })   
      Message.unsafe_create({ :subject => "The subject",
                              :content => "Lorem ipsum" }.merge(options))
    end
end