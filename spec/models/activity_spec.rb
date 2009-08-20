require File.dirname(__FILE__) + '/../spec_helper'

describe Activity do
  before(:each) do
    @dog = dogs(:dana)
    @commenter = dogs(:max)
  end

  it "should delete a post activity along with its parent item" do
    @post = topics(:one).posts.unsafe_create(:body => "Hey there", 
                                             :dog => @dog)
    destroy_should_remove_activity(@post)
  end
  
  it "should delete a comment activity along with its parent item" do
    @comment = @dog.comments.unsafe_create(:body => "Hey there",
                                              :commenter => @commenter)
    destroy_should_remove_activity(@comment)
  end
  
  it "should delete topic & post activities along with the parent items" do
    @topic = forums(:one).topics.unsafe_create(:name => "A topic",
                                               :dog => @dog)
    post = @topic.posts.unsafe_create(:body => "body", :dog =>  @dog)
    @topic.posts.each do |post|
      destroy_should_remove_activity(post)
    end
    destroy_should_remove_activity(@topic)
  end
  
  it "should delete an associated connection" do
    @dog = dogs(:dana)
    @contact = dogs(:max)
    Connection.connect(@dog, @contact)
    @connection = Connection.conn(@dog, @contact)
    destroy_should_remove_activity(@connection, :breakup)
  end
  
  before(:each) do
    # Create an activity.
    @dog.comments.unsafe_create(:body => "Hey there",
                                   :commenter => @commenter)
  end
  
  it "should have a nonempty global feed" do
    Activity.global_feed.should_not be_empty
  end
  
  it "should not show activities for dogs who are inactive" do
    @dog.activities.collect(&:dog).should include(@commenter)
    @commenter.toggle!(:deactivated)
    @commenter.should be_deactivated
    Activity.global_feed.should be_empty
    @dog.reload
    @dog.activities.collect(&:dog).should_not include(@commenter)
  end
  
  private
  
  # TODO: do this in a more RSpecky way.
  def destroy_should_remove_activity(obj, method = :destroy)
    Activity.find_by_item_id(obj).should_not be_nil
    obj.send(method)
    Activity.find_by_item_id(obj).should be_nil
  end
end
