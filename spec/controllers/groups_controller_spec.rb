require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe GroupsController do
 
  before(:each) do
    @group = groups(:public)
    photos = [mock_photo(:primary => true), mock_photo]
    photos.stub!(:find_all_by_primary).and_return(photos.select(&:primary?))
    @group.stub!(:photos).and_return(photos)
    @dog = dogs(:dana)
    login_as(:aaron)
  end
  
  describe "groups pages" do
    integrate_views
        
    it "should have a working index" do
      get :index
      response.should be_success
      response.should render_template("index")
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
      get :show, :id => @group
      response.should be_success
      response.should render_template("show")
    end
    
    it "should have a working edit page" do
      login_as(:quentin)
      get :edit, :id => @group
      response.should be_success
      response.should render_template("edit")
    end
    
    it "should redirect to home for deactivated groups" do
      @group.toggle!(:deactivated)
      get :show, :id => @group
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
    it 'allows creation of new group profile' do
      lambda do
        create_group
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
      get :edit, :id => @group
      response.should be_success
      response.should render_template("edit")
    end
    
    it "should allow mass assignment to name" do
      put :update, :id => @group, :group => { :name => "Foo Bar" },
                   :type => "info_edit"
      assigns(:group).name.should == "Foo Bar"
      response.should redirect_to(group_url(assigns(:group)))
    end
      
    it "should allow mass assignment to description" do
      put :update, :id => @group, :group => { :description => "Me!" },
                   :type => "info_edit"
      assigns(:group).description.should == "Me!"
      response.should redirect_to(group_url(assigns(:group)))
    end
    
    it "should allow mass assignment to breed" do
      put :update, :id => @group, :group => { :breed_id => breeds(:bullgroup).id },
                   :type => "info_edit"
      assigns(:group).breed.should == breeds(:bullgroup)
      response.should redirect_to(group_url(assigns(:group)))
    end       
    
    it "should allow mass assignment to date of birth" do
      dob = 2.years.ago
      put :update, :id => @group, :group => { :dob => dob },
                   :type => "info_edit"
      assigns(:group).dob.should == dob
      response.should redirect_to(group_url(assigns(:group)))
    end 
    
    it "should render edit page on invalid update" do
      put :update, :id => @group, :group => { :name => nil },
                   :type => "info_edit"
      response.should be_success
      response.should render_template("edit")
    end
    
    it "should require the owner" do
      login_as(:aaron)
      put :update, :id => @group
      response.should redirect_to(home_url)
    end
  end
  
  describe "show" do
    integrate_views
    
    it "should display the edit link for current user" do
      login_as(:quentin)
      get :show, :id => @group
      response.should have_tag("a[href=?]", edit_group_path(@group))
    end
    
    it "should not display the edit link for other viewers" do
      login_as(:aaron)
      get :show, :id => @group
      response.should_not have_tag("a[href=?]", edit_group_path(@group))
    end
    
    it "should not display the edit link for non-logged-in viewers" do
      logout
      get :show, :id => @group
      response.should_not have_tag("a[href=?]", edit_group_path(@group))
    end
    
    it "should not display a deactivated group" do
      @group.toggle!(:deactivated)
      get :show, :id => @group
      response.should redirect_to(home_url)
    end
    
    it "should display deactivated group for owner" do
      login_as(:quentin)
      @group.toggle!(:deactivated)
      get :show, :id => @group
      response.should be_success
    end
    
    it "should display break up link if connected" do
      login_as(:quentin)
      @contact = groups(:max)
      conn = Connection.connect(@group, @contact)
      get :show, :id => @contact.reload
      response.should have_tag("a[href=?]", connection_path(conn))
    end
    
    it "should not display break up link if not connected" do
      login_as(:quentin)
      @contact = groups(:max)
      get :show, :id => @contact.reload
      response.should_not have_tag("a", :text => "Remove Connection")
    end
  end
  
  private
    def create_group(options = {})
      group_hash = { :name => "Quire" }
      post :create, :group => group_hash.merge(options)
      assigns(:group)
    end
end
