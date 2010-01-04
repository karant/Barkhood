require File.dirname(__FILE__) + '/../spec_helper'
 
describe DogsController do
 
  before(:each) do
    @dog = dogs(:dana)
    photos = [mock_photo(:primary => true), mock_photo]
    photos.stub!(:find_all_by_primary).and_return(photos.select(&:primary?))
    @dog.stub!(:photos).and_return(photos)
    @person = people(:aaron)
    login_as(:aaron)
  end
  
  describe "dogs pages" do
    integrate_views
        
    it "should have a working index" do
      get :index
      response.should be_success
      response.should render_template("dogs/_dog_link.html.erb")
    end
 
    it "should have a working new page" do
      get :new
      response.should be_success
      response.should render_template("new")
    end
    
    it "should not allow non-logged-in users to view new page" do
      logout
      get :new
      response.should redirect_to(login_url)
    end
    
    it "should have a working show page" do
      get :show, :id => @dog
      response.should be_success
      response.should render_template("show")
    end
    
    it "should have a working edit page" do
      login_as(:quentin)
      get :edit, :id => @dog
      response.should be_success
      response.should render_template("edit")
    end
    
    it "should redirect to home for deactivated dogs" do
      @dog.toggle!(:deactivated)
      get :show, :id => @dog
      response.should redirect_to(home_url)
      flash[:error].should =~ /not active/
    end
    
    it "should redirect to home for email unverified users" do
      enable_email_notifications
      @person.email_verified = false; @person.save!
      @person.should_not be_active
      get :new
      response.should redirect_to(logout_url)
    end
  end
  
  describe "create" do 
    it 'allows creation of new dog profile' do
      lambda do
        create_dog
        response.should be_redirect
      end.should change(Dog, :count).by(1)
    end
  end
  
  describe "edit" do
    integrate_views
    
    before(:each) do
      login_as(:quentin)
    end
    
    it "should render the edit page when photos are present" do
      get :edit, :id => @dog
      response.should be_success
      response.should render_template("edit")
    end
    
    it "should allow mass assignment to name" do
      put :update, :id => @dog, :dog => { :name => "Foo Bar" },
                   :type => "info_edit"
      assigns(:dog).name.should == "Foo Bar"
      response.should redirect_to(dog_url(assigns(:dog)))
    end
      
    it "should allow mass assignment to description" do
      put :update, :id => @dog, :dog => { :description => "Me!" },
                   :type => "info_edit"
      assigns(:dog).description.should == "Me!"
      response.should redirect_to(dog_url(assigns(:dog)))
    end
    
    it "should allow mass assignment to breed" do
      put :update, :id => @dog, :dog => { :breed_id => breeds(:bulldog).id },
                   :type => "info_edit"
      assigns(:dog).breed.should == breeds(:bulldog)
      response.should redirect_to(dog_url(assigns(:dog)))
    end       
    
    it "should allow mass assignment to date of birth" do
      dob = 2.years.ago
      put :update, :id => @dog, :dog => { :dob => dob },
                   :type => "info_edit"
      assigns(:dog).dob.should == dob
      response.should redirect_to(dog_url(assigns(:dog)))
    end 
    
    it "should render edit page on invalid update" do
      put :update, :id => @dog, :dog => { :name => nil },
                   :type => "info_edit"
      response.should be_success
      response.should render_template("edit")
    end
    
    it "should require the owner" do
      login_as(:aaron)
      put :update, :id => @dog
      response.should redirect_to(home_url)
    end
  end
  
  describe "show" do
    integrate_views
    
    it "should display the edit link for current user" do
      login_as(:quentin)
      get :show, :id => @dog
      response.should have_tag("a[href=?]", edit_dog_path(@dog))
    end
    
    it "should not display the edit link for other viewers" do
      login_as(:aaron)
      get :show, :id => @dog
      response.should_not have_tag("a[href=?]", edit_dog_path(@dog))
    end
    
    it "should not display the edit link for non-logged-in viewers" do
      logout
      get :show, :id => @dog
      response.should_not have_tag("a[href=?]", edit_dog_path(@dog))
    end
    
    it "should not display a deactivated dog" do
      @dog.toggle!(:deactivated)
      get :show, :id => @dog
      response.should redirect_to(home_url)
    end
    
    it "should display deactivated dog for owner" do
      login_as(:quentin)
      @dog.toggle!(:deactivated)
      get :show, :id => @dog
      response.should be_success
    end
    
    it "should display break up link if connected" do
      login_as(:quentin)
      @contact = dogs(:max)
      conn = Connection.connect(@contact, @dog)
      get :show, :id => @contact.reload
      response.should have_tag("a[href=?]", connection_path(conn))
    end
    
    it "should not display break up link if not connected" do
      login_as(:quentin)
      @contact = dogs(:max)
      get :show, :id => @contact.reload
      response.should_not have_tag("a", :text => "Remove Connection")
    end
  end
  
  private
 
    def create_dog(options = {})
      dog_hash = { :name => "Quire" }
      post :create, :dog => dog_hash.merge(options)
      assigns(:dog)
    end
end
