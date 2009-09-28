require File.dirname(__FILE__) + '/../../spec_helper'

describe Admin::GroupsController do
  integrate_views
  
  before(:each) do
    request.env['HTTP_REFERER'] = "http://test.host/previous/page"    
  end
  
  it "should redirect a non-logged-in user" do
    get :index
    response.should be_redirect
  end
  
  it "should redirect a non-admin user" do
    login_as :aaron
    get :index
    response.should be_redirect
  end

  it "should render successfully for an admin user" do
    login_as :admin
    get :index
    response.should be_success
  end
  
  describe "group modifications" do
    
    before(:each) do
      @admin = login_as(:admin)
      @group = groups(:public)
    end
    
    it "should delete a group" do
      lambda do
        delete :destroy, :id => @group
        response.should redirect_to(admin_groups_path)
      end.should change(Group, :count).by(-1)
    end
  end  
end
