require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe GroupsController do
 
  before(:each) do
    @group = groups(:public)
    @private_group = groups(:private)
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
    
    it "should have a working members page" do
      get :members, :id => @group
      response.should be_success
      response.should render_template("members")
    end
    
    it "should have a working photos page" do
      get :photos, :id => @group
      response.should be_success
      response.should render_template("photos")
    end
  end
  
  describe "create" do 
    it 'allows creation of new group profile' do
      lambda do
        create_group
        response.should be_redirect
      end.should change(Group, :count).by(1)
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
    
    it "should allow mass assignment to mode" do
      put :update, :id => @group, :group => { :mode => Group::PRIVATE },
                   :type => "info_edit"
      assigns(:group).mode.should == Group::PRIVATE
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
    
    it "should display edit members link if current person is owner" do
      login_as(:quentin)
      get :show, :id => @group
      response.should have_tag("a[href=?]", members_group_path(@group))
    end
    
    it "should not display edit members link of current person is not owner" do
      login_as(:aaron)
      get :show, :id => @group
      response.should_not have_tag("a[href=?]", members_group_path(@group))
    end
    
    it "should display invite members link for owner of hidden group" do
      login_as(:quentin)
      @group.update_attribute(:mode, Group::HIDDEN)
      get :show, :id => @group
      response.should have_tag("a[href=?]", invite_group_path(@group))
    end
    
    it "should not display invite members link for non-hidden group" do
      login_as(:quentin)
      get :show, :id => @group
      response.should_not have_tag("a[href=?]", invite_group_path(@group))      
    end
    
    it "should display join link for non-member" do
      login_as(:aaron)
      get :show, :id => @group
      response.should have_tag("a[href=?]", group_memberships_path(@group, :dog_id => dogs(:max)))
    end
    
    it "should display leave group link for member" do
      login_as(:quentin)
      get :show, :id => @group
      response.should have_tag("a[href=?]", membership_path(Membership.mem(dogs(:nola), @group)))
    end
    
    it "should display you've been invited link for invited person" do
      login_as(:aaron)
      Membership.invite(dogs(:max), @group)
      get :show, :id => @group
      response.should have_tag("a[href=?]", edit_membership_path(Membership.mem(dogs(:max), @group)))      
    end
    
    it "should display group owner wording" do
      login_as(:quentin)
      get :show, :id => @group
      response.should have_text(/Group owner/)       
    end
    
    it "should display request pending wording" do
      login_as(:aaron)
      Membership.request(dogs(:max), @private_group)
      get :show, :id => @private_group
      response.should have_text(/Request pending/)       
    end
  end
  
  private
    def create_group(options = {})
      group_hash = { :name => "Group", :description => "Description", :mode => Group::PUBLIC, :dog_id => dogs(:max) }
      post :create, :group => group_hash.merge(options)
      assigns(:group)
    end
end
