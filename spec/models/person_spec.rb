require File.dirname(__FILE__) + '/../spec_helper'

describe Person do

  before(:each) do
    @person = people(:quentin)
  end

  describe "attributes" do
    it "should be valid" do
      create_person.should be_valid
    end

    it 'requires password' do
      p = create_person(:password => nil)
      p.errors.on(:password).should_not be_nil
    end

    it 'requires password confirmation' do
      p = create_person(:password_confirmation => nil)
      p.errors.on(:password_confirmation).should_not be_nil
    end

    it 'requires email' do
      p = create_person(:email => nil)
      p.errors.on(:email).should_not be_nil
    end
    
    it "should prevent duplicate email addresses using a unique key" do
      create_person(:save => true)
      duplicate = create_person
      lambda do
        # Pass 'false' to 'save' in order to skip the validations.
        duplicate.save(false)
      end.should raise_error(ActiveRecord::StatementInvalid)
    end

    it "should strip spaces in email field" do
      create_person(:email => 'example@example.com ').should be_valid
    end
    
    it "should allow a plus sign in the email address" do
      create_person(:email => 'foo+bar@example.com').should be_valid
    end
  end 
  
  describe "utility methods" do    
    it "should return an array of group ids for all dogs" do
      @person.group_ids.should be_kind_of(Array)
      @person.group_ids.should contain(groups(:public).id)
    end
  end  
  
  describe "associations" do
    before(:each) do
      @contact = dogs(:buba)
    end
    
    it "should have dogs" do
      @person.dogs.should == [dogs(:dana), dogs(:nola), dogs(:deactivated)]
    end

    describe "common contacts" do

      before(:each) do
        @parker = dogs(:parker)
        @nola = dogs(:nola)
        Connection.connect(@parker, @contact)
        Connection.connect(@nola, @contact)
      end

      it "should have common contacts with someone" do
        common_contacts = @person.common_contacts_with(@parker)
        common_contacts.size.should == 1
        common_contacts.should be_a_kind_of(WillPaginate::Collection)
        common_contacts.should == [@contact]
      end
      
      it "should not include non-common contacts" do
        sharik = dogs(:sharik)
        Connection.connect(@parker, sharik)
        @person.common_contacts_with(@parker).should_not contain(sharik)
      end

      it "should exclude dogs with deactivated owners from common contacts" do
        @contact.owner.toggle!(:deactivated)
        common_contacts = @person.common_contacts_with(@parker)
        common_contacts.should be_empty
      end   
    end  
    
    describe "message associations" do     
      it "should have sent messages" do
        @person.sent_messages.should_not be_nil
      end
  
      it "should have received messages" do
        @person.received_messages.should_not be_nil
      end   
      
      it "should have unread messages" do
        @person.has_unread_messages?.should be_true
      end
    end
  end

  describe "authentication" do
    it 'resets password' do
      @person.update_attributes(:password => 'newp',
                                :password_confirmation => 'newp')
      Person.authenticate('quentin@example.com', 'newp').should == @person
    end

    it 'authenticates person' do
      Person.authenticate('quentin@example.com', 'test').should == @person
    end

    it "should strip spaces for email" do
      Person.authenticate('quentin@example.com ', 'test').should == @person
    end

    it "should authenticate case-insensitively" do
      Person.authenticate('queNTin@eXample.com', 'test').should == @person
    end

    it 'sets remember token' do
      @person.remember_me
      @person.remember_token.should_not be_nil
      @person.remember_token_expires_at.should_not be_nil
    end

    it 'unsets remember token' do
      @person.remember_me
      @person.remember_token.should_not be_nil
      @person.forget_me
      @person.remember_token.should be_nil
    end

    it 'remembers me for one week' do
      before = 1.week.from_now.utc
      @person.remember_me_for 1.week
      after = 1.week.from_now.utc
      @person.remember_token.should_not be_nil
      @person.remember_token_expires_at.should_not be_nil
      @person.remember_token_expires_at.between?(before, after).should be_true
    end

    it 'remembers me until one week' do
      time = 1.week.from_now.utc
      @person.remember_me_until time
      @person.remember_token.should_not be_nil
      @person.remember_token_expires_at.should_not be_nil
      @person.remember_token_expires_at.should == time
    end

    it 'remembers me default two weeks' do
      before = 2.years.from_now.utc
      @person.remember_me
      after = 2.years.from_now.utc
      @person.remember_token.should_not be_nil
      @person.remember_token_expires_at.should_not be_nil
      @person.remember_token_expires_at.between?(before, after).should be_true
    end
  end

  describe "password edit" do

    before(:each) do
      @password = @person.unencrypted_password
      @newpass  = "foobar"
    end

    it "should change the password" do
      @person.change_password?(:verify_password       => @password,
                               :new_password          => @newpass,
                               :password_confirmation => @newpass)
      @person.unencrypted_password.should == @newpass
    end

    it "should not change password on failed verification" do
      @person.change_password?(:verify_password       => @password + "not!",
                               :new_password          => @newpass,
                               :password_confirmation => @newpass)
      @person.unencrypted_password.should_not == @newpass
      @person.errors.on(:password).should =~ /incorrect/
    end

    it "should not change password on failed agreement" do
      @person.change_password?(:verify_password       => @password,
                               :new_password          => @newpass + "not!",
                               :password_confirmation => @newpass)
      @person.unencrypted_password.should_not == @newpass
      @person.errors.on(:password).should =~ /match/
    end

    it "should not allow invalid new password" do
      @newpass = ""
      @person.change_password?(:verify_password       => @password,
                               :new_password          => @newpass,
                               :password_confirmation => @newpass)
      @person.unencrypted_password.should_not == @newpass
      @person.errors.on(:password).should_not be_nil
    end
  end

  describe "activation" do

    it "should deactivate a person" do
      @person.should_not be_deactivated
      @person.toggle(:deactivated)
      @person.should be_deactivated
    end

    it "should reactivate a person" do
      @person.toggle(:deactivated)
      @person.should be_deactivated
      @person.toggle(:deactivated)
      @person.should_not be_deactivated
    end
    
    it "should have nil email verification" do
      person = create_person
      person.email_verified.should be_nil
    end

    it "should have a working active? helper boolean" do
      @person.should be_active
      enable_email_notifications
      @person.email_verified = false
      @person.should_not be_active
      @person.email_verified = true
      @person.should be_active
    end
  end
  
  describe "mostly active" do
    it "should include a recently logged-in person" do
      Person.mostly_active.should contain(@person)
    end
    
    it "should not include a deactivated person" do
      @person.toggle!(:deactivated)
      Person.mostly_active.should_not contain(@person)
    end
    
    it "should not include an email unverified person" do
      enable_email_notifications
      @person.email_verified = false; @person.save!
      Person.mostly_active.should_not contain(@person)      
    end
    
    it "should not include a person who has never logged in" do
      @person.last_logged_in_at = nil; @person.save
      Person.mostly_active.should_not contain(@person)
    end
    
    it "should not include a person who logged in too long ago" do
      @person.last_logged_in_at = Person::TIME_AGO_FOR_MOSTLY_ACTIVE - 1
      @person.save
      Person.mostly_active.should_not contain(@person)
    end
  end

  describe "admin" do

    before(:each) do
      @person = people(:admin)
    end

    it "should un-admin a person" do
      @person.should be_admin
      @person.toggle(:admin)
      @person.should_not be_admin
    end

    it "should have a working last_admin? method" do
      @person.should be_last_admin
      people(:aaron).toggle!(:admin)
      @person.should_not be_last_admin
    end
  end
  
  describe "active class methods" do
    it "should not return deactivated people" do
      @person.toggle!(:deactivated)
      [:active, :all_active].each do |method|
        Person.send(method).should_not contain(@person)
      end
    end
    
    it "should not return email unverified people" do
      @person.email_verified = false
      @person.save!
      [:active, :all_active].each do |method|
        Person.send(method).should_not contain(@person)
      end
    end
  end
    
  protected

    def create_person(options = {})
      record = Person.new({ :email => 'quire@example.com',
                            :password => 'quire',
                            :password_confirmation => 'quire',
                            :address => '4188 Justin Way, Sacramento CA 95826'}.merge(options))
      record.valid?
      record.save! if options[:save]
      record
    end
end
