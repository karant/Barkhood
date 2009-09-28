require File.dirname(__FILE__) + '/../spec_helper'

describe CommentsController do
  
  describe "blog comments" do
    integrate_views
  
    before(:each) do
      login_as(:aaron)
      @commenter = dogs(:max)
      @blog   = dogs(:dana).blog
      @post   = posts(:blog_post)
    end
  
    it "should have working pages" do
      with_options :blog_id => @blog, :post_id => @post do |page|
        page.get    :new
        page.post   :create, :comment => { :commenter_id => @commenter }
        page.delete :destroy, :id => comments(:blog_comment)
      end
    end
    
    it "should create a blog comment" do
      lambda do
        post :create, :blog_id => @blog, :post_id => @post,
                      :comment => { :body => "The body", :commenter_id => @commenter }
        response.should redirect_to(blog_post_url(@blog, @post))
      end.should change(Comment, :count).by(1)
    end
    
    it "should create the right blog comment associations" do
      lambda do
        post :create, :blog_id => @blog, :post_id => @post,
                      :post => { :body => "The body", :commenter_id => @commenter }
        assigns(:comment).commenter.should == @commenter
        assigns(:comment).post.should == @post
      end 
    end
    
    it "should render the new template on creation failure" do
      post :create, :blog_id => @blog, :post_id => @post, :comment => { :commenter_id => @commenter }
      response.should render_template("blog_post_new")
    end
    
    it "should associate a commenter to the comment" do
      post :create, :blog_id => @blog, :post_id => @post,
                    :comment => { :body => "The body", :commenter_id => @commenter }
      assigns(:comment).commenter.should == @commenter
    end
    
    it "should allow destroy" do
      login_as @blog.owner.owner
      comment = comments(:blog_comment)
      delete :destroy, :blog_id => @blog, :post_id => @post, :id => comment
      comment.should_not exist_in_database
    end
    
    it "should require the correct user to destroy a comment" do
      login_as(:aaron)
      comment = comments(:blog_comment)
      delete :destroy, :blog_id => @blog, :post_id => @post, :id => comment
      response.should redirect_to(home_url)
    end
  end

  
  describe "wall comments" do
    integrate_views
  
    before(:each) do
      login_as(:aaron)
      @commenter = dogs(:max)
      @dog    = dogs(:dana)
      Connection.connect(@dog, @commenter)
    end
  
    it "should have working pages" do
      with_options :dog_id => @dog do |page|
        page.get    :new
        page.post   :create, :comment => { :commenter_id => @commenter }
        page.delete :destroy, :id => comments(:wall_comment)
      end
    end
  
    it "should allow create" do
      lambda do
        post :create, :dog_id => @dog,
                      :comment => { :body => "The body", :commenter_id => @commenter }
        #should go directly to the dog's wall              
        response.should redirect_to(dog_url(@dog)+'#tWall')
      end.should change(Comment, :count).by(1)
    end
      
    it "should associate a dog to a comment" do
      with_options :dog_id => @dog do |page|
        page.post :create, :comment => { :body => "The body", :commenter_id => @commenter }
        assigns(:comment).commenter.should == @commenter
        assigns(:comment).commentable.should == @dog
      end
    end
    
    it "should render the new template on creation failure" do
      post :create, :dog_id => @dog, :comment => { :body => "", :commenter_id => @commenter }
      response.should render_template("wall_new")
    end
    
    it "should allow destroy for dog" do
      login_as @dog.owner
      comment = comments(:wall_comment)
      delete :destroy, :dog_id => @dog, :id => comment
      comment.should_not exist_in_database
    end
    
    it "should allow destroy for commenter" do
      comment = comments(:wall_comment)
      login_as comment.commenter.owner
      delete :destroy, :dog_id => @dog, :id => comment
      comment.should_not exist_in_database
    end
    
    it "should protect the destroy action" do
      login_as :kelly
      comment = comments(:wall_comment)
      delete :destroy, :dog_id => @dog, :id => comment
      response.should redirect_to(home_url)
    end
  end
end
