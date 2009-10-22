require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe MembershipsController do
  integrate_views
  
  before(:each) do
    login_as(:aaron)
    @dog = dogs(:max)
    @group = groups(:private)
  end
  
  it "should protect the create page" do
    logout
    post :create
    response.should redirect_to(login_url)
  end
  
  it "should create a new membership request" do
    Membership.should_receive(:request).with(@dog, @group).
      and_return(true)
    post :create, :group_id => @group, :dog_id => @dog
    response.should redirect_to(home_url)
  end
  
  describe "with existing membership" do
    integrate_views
    
    before(:each) do
      Membership.invite(@dog, @group)
      @membership = Membership.mem(@dog, @group)
    end
    
    it "should get the edit page" do
      get :edit, :id => @membership
      response.should be_success
    end
    
    it "should require the right current person" do
      login_as :quentin
      get :edit, :id => @membership
      response.should redirect_to(home_url)
    end

    it "should accept the membership" do
      put :update, :id => @membership, :commit => "Accept"
      Membership.find(@membership).status.should == Membership::ACCEPTED
      response.should redirect_to(home_url)
    end
    
    it "should decline the membership" do
      put :update, :id => @membership, :commit => "Decline"
      @membership.should_not exist_in_database
      response.should redirect_to(home_url)
    end
  
    it "should end a membership" do
      lambda do
        delete :destroy, :id => @membership
        response.should redirect_to(dog_memberships_url(@dog))
      end.should change(Membership, :count).by(-1)
    end
    
    it "should not allow to end membership of group owner" do
      membership = memberships(:hidden_max)
      lambda do
        delete :destroy, :id => membership
        response.should redirect_to(dog_memberships_url(membership.dog))
      end.should_not change(Membership, :count)
    end
  end  
  
  describe "for invitations" do
    integrate_views
    
    before(:each) do
      @membership = memberships(:public_buba)
    end
    
    it "should subscribe a requested member" do
      login_as(:quentin)
      post :subscribe, :id => @membership
      Membership.find(@membership).status.should == Membership::ACCEPTED
      response.should redirect_to(members_group_path(@membership.group))
    end
    
    it "should not subscribe a request if current user is not owner" do
      login_as(:aaron)
      post :subscribe, :id => @membership
      response.should redirect_to(home_url)
    end
    
    it "should unsubscribe a member" do
      @membership = memberships(:public_nola)
      lambda do
        login_as(:quentin)
        delete :unsubscribe, :id => @membership
        response.should redirect_to(members_group_path(@membership.group))
      end.should change(Membership, :count).by(-1)
    end
    
    it "should not allow unsubscribe if current person is not group owner" do
      @membership = memberships(:public_nola)
      login_as(:aaron)
      delete :unsubscribe, :id => @membership
      response.should redirect_to(home_url)
    end
    
    it "should not allow to unsubsribe a group owner" do
      membership = memberships(:hidden_max)
      lambda do
        delete :unsubscribe, :id => membership
        response.should redirect_to(members_group_path(membership.group))
      end.should_not change(Membership, :count)
    end
  end
end
