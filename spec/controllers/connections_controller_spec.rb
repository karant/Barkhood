require File.dirname(__FILE__) + '/../spec_helper'

describe ConnectionsController do
  integrate_views
  
  before(:each) do
    login_as(:quentin)
    @dog = dogs(:dana)
    @contact = dogs(:max)
  end
  
  it "should protect the create page" do
    logout
    post :create
    response.should redirect_to(login_url)
  end
  
  it "should create a new connection request" do
    Connection.should_receive(:request).with(@dog, @contact).
      and_return(true)
    post :create, :dog_id => @dog, :contact_id => @contact
    response.should redirect_to(home_url)
  end
  
  describe "with existing connection" do
    integrate_views
    
    before(:each) do
      Connection.request(@dog, @contact)
      @connection = Connection.conn(@dog, @contact)
    end
    
    it "should get the edit page" do
      get :edit, :id => @connection
      response.should be_success
    end
    
    it "should require the right current person" do
      login_as :aaron
      get :edit, :id => @connection
      response.should redirect_to(home_url)
    end

    it "should accept the connection" do
      put :update, :id => @connection, :commit => "Accept"
      Connection.find(@connection).status.should == Connection::ACCEPTED
      response.should redirect_to(home_url)
    end
    
    it "should decline the connection" do
      put :update, :id => @connection, :commit => "Decline"
      @connection.should_not exist_in_database
      response.should redirect_to(home_url)
    end
  
    it "should end a connection" do
      delete :destroy, :id => @connection, :dog_id => @dog
      response.should redirect_to(dog_connections_url(@dog))
    end
  end  
end
