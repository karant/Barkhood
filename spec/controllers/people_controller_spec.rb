require File.dirname(__FILE__) + '/../spec_helper'

describe PeopleController do

  before(:each) do
    @person = people(:quentin)
    photos = [mock_photo(:primary => true), mock_photo]
    photos.stub!(:find_all_by_primary).and_return(photos.select(&:primary?))
    @person.stub!(:photos).and_return(photos)
    login_as(:aaron)
  end
  
  describe "people pages" do
    integrate_views

    it "should have a working new page" do
      get :new
      response.should be_success
      response.should render_template("new")
    end
    
    it "should allow non-logged-in users to view new page" do
      logout
      get :new
      response.should be_success
    end
    
    it "should have a working show page" do
      login_as(:quentin)
      get :show, :id => @person
      response.should be_success
      response.should render_template("show")
    end
    
    it "should have a working edit page" do
      login_as @person
      get :edit, :id => @person
      response.should be_success
      response.should render_template("edit")
    end
  end
  
  describe "create" do
    before(:each) do
      logout
    end

    it 'allows signup' do
      lambda do
        create_person
        response.should be_redirect      
      end.should change(Person, :count).by(1)
    end
  
    it 'requires password on signup' do
      lambda do
        create_person(:password => nil)
        assigns[:person].errors.on(:password).should_not be_nil
        response.should be_success
      end.should_not change(Person, :count)
    end
  
    it 'requires password confirmation on signup' do
      lambda do
        create_person(:password_confirmation => nil)
        assigns[:person].errors.on(:password_confirmation).should_not be_nil
        response.should be_success
      end.should_not change(Person, :count)
    end

    it 'requires email on signup' do
      lambda do
        create_person(:email => nil)
        assigns[:person].errors.on(:email).should_not be_nil
        response.should be_success
      end.should_not change(Person, :count)
    end
    
    it 'requires address on signup' do
      lambda do
        create_person(:address => nil)
        assigns[:person].errors.on(:address).should_not be_nil
        response.should be_success
      end.should_not change(Person, :count)
    end
    
    describe "email verifications" do
      
      before(:each) do
        logout
        @preferences = preferences(:one)
      end
      
      describe "when not verifying email" do
        it "should create an active user" do
          create_person
          assigns(:person).should_not be_deactivated
        end
      end
      
      describe "when verifying email" do
        
        before(:each) do
          @preferences.toggle!(:email_verifications)
        end
    
        it "should create a person with false email_verified" do
          person = create_person
          person.should_not be_deactivated
          person.should_not be_email_verified
          person.email_verifications.should_not be_empty
        end
        
        it "should have the right notice" do
          person = create_person
          flash[:notice].should =~ /activate your account/
          response.should redirect_to(home_url)
        end
        
        it "should verify a person" do
          person = create_person
          verification = assigns(:person).email_verifications.last
          get :verify_email, :id => verification.code
          person.reload.should_not be_deactivated
          person.should be_email_verified
          response.should redirect_to(person_path(person))
        end
        
        it "should not log the person in" do
          person = create_person
          controller.send(:logged_in?).should be_false
        end
          
        it "should not have an auth token" do
          create_person
          response.cookies["auth_token"].should == nil
        end
        
        it "should verify a person even if they're logged in" do
          person = create_person
          login_as(person)
          verification = person.email_verifications.last
          get :verify_email, :id => verification.code
          person.reload.should_not be_deactivated
          response.should redirect_to(person_path(person))
        end
        
        it "should redirect home on failed verification" do
          get :verify_email, :id => "invalid"
          response.should redirect_to(home_url)
        end
      end
    end
  end
  
  describe "edit" do
    integrate_views
    
    before(:each) do
      @person = login_as(:quentin)
    end
    
    it "should render the edit page when photos are present" do
      get :edit, :id => @person
      response.should be_success
      response.should render_template("edit")
    end
      
    it "should allow mass assignment to address" do
      put :update, :id => @person, :person => { :address => "111 Capitol Ave, Sacramento CA" },
                   :type => "info_edit"
      assigns(:person).address.should == "111 Capitol Ave, Sacramento CA"
      response.should redirect_to(person_url(assigns(:person)))
    end
    
    it "should render edit page on invalid update" do
      put :update, :id => @person, :person => { :email => "foo" },
                   :type => "info_edit"
      response.should be_success
      response.should render_template("edit")
    end
    
    it "should require the right authorized user" do
      login_as(:aaron)
      put :update, :id => @person
      response.should redirect_to(home_url)
    end
    
    it "should change the password" do
      current_password = @person.unencrypted_password
      newpass = "dude"
      put :update, :id => @person,
                   :person => { :verify_password => current_password,
                                :new_password => newpass,
                                :password_confirmation => newpass },
                   :type => "password_edit"
      response.should redirect_to(person_url(@person))
    end
  end
  
  describe "show" do
    integrate_views    
    
    it "should display the edit link for current user" do
      login_as @person
      get :show, :id => @person
      response.should have_tag("a[href=?]", edit_person_path(@person))
    end
    
    it "should not display user if it is not current user" do
      login_as(:aaron)
      get :show, :id => @person
      response.should redirect_to(home_url)
    end
    
    it "should log out a deactivated person" do
      login_as(@person)
      @person.toggle!(:deactivated)
      get :show, :id => @person
      response.should redirect_to(logout_url)      
    end
    
    it "should log out a an email unverified user" do
      person = people(:aaron)
      enable_email_notifications
      person.email_verified = false; person.save!
      person.should_not be_active
      get :show, :id => person
      response.should redirect_to(logout_url)
    end    
  end
  
  private

    def create_person(options = {})
      person_hash = { :email => 'quire@foo.com',
                      :name => 'Quire',
                      :password => 'quux', :password_confirmation => 'quux',
                      :address => '4188 Justin Way, Sacramento CA 95826'}
      post :create, :person => person_hash.merge(options)
      assigns(:person)
    end
end
