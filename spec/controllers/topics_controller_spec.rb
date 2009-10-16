require File.dirname(__FILE__) + '/../spec_helper'

describe TopicsController do
  integrate_views

  before(:each) do
    @topic = topics(:one)
    @dog = dogs(:dana)
    @forum = forums(:one)
  end
  
  it "should require login for new" do
    get :new
    response.should redirect_to(login_url)
  end
  
  it "should have working pages" do
    login_as :quentin
    
    with_options :forum_id => forums(:one) do |page|
      page.get    :new
      page.get    :edit,    :id => @topic
      page.post   :create,  :topic => { :name => "The topic", :dog_id => @dog }
      page.put    :update,  :id => @topic
      page.delete :destroy, :id => @topic
    end
  end  
  
  it "should associate a dog to a topic" do
    person = login_as(:quentin)
    with_options :forum_id => forums(:one) do |page|
      page.post :create, :topic => { :name => "The topic", :dog_id => @dog }
      assigns(:topic).dog.should == @dog
    end
  end
  
  it "should redirect properly on topic deletion" do
    person = login_as(:admin)
    delete :destroy, :id => @topic, :forum_id => @forum
    response.should redirect_to(forum_url(@forum))
  end
  
  it "should default post author to topic author for topic author's owner" do
    login_as :quentin
    topic = @forum.topics.build(:name => "New topic")
    topic.dog = dogs(:nola)
    topic.save      
    topic.should be_valid
    get :show, :forum_id => @forum, :id => topic
    assigns(:post).dog.should == dogs(:nola)
  end
  
  it "should not default post author if topic's owner is not current user" do
    login_as :aaron
    topic = @forum.topics.build(:name => "New topic")
    topic.dog = dogs(:nola)
    topic.save
    topic.should be_valid
    get :show, :forum_id => @forum, :id => topic
    assigns(:post).dog.should be_nil   
  end  
end
