require File.dirname(__FILE__) + '/../spec_helper'

describe PostsController do
  include BlogsHelper

  describe "forum posts" do
    integrate_views
  
    before(:each) do
      @person = login_as(:quentin)
      @dog = dogs(:dana)
      @forum  = forums(:one)
      @topic  = topics(:one)
      @post   = posts(:forum)
    end
    
    it "should have working pages" do
      with_options :forum_id => @forum, :topic_id => @topic do |page|
        page.get    :index
        page.get    :new
        page.get    :edit,    :id => @post
        page.post   :create,  :post => { :dog_id => @dog }
        page.put    :update,  :id => @post
        page.delete :destroy, :id => @post
      end
    end

    it "should create a forum post" do
      lambda do
        post :create, :forum_id => @forum, :topic_id => @topic,
                      :post => { :body => "The body", :dog_id => @dog }
        topics = forum_topic_url(@forum, @topic, :posts => 2)
        response.should redirect_to(topics)
      end.should change(ForumPost, :count).by(1)
    end
  
    it "should associate a person to a post" do
      with_options :forum_id => @forum, :topic_id => @topic do |page|
        page.post :create, :post => { :body => "The body", :dog_id => @dog }
        assigns(:post).dog.should == @dog
      end
    end
    
    it "should render the new template on creation failure" do
      post :create, :forum_id => @forum, :topic_id => @topic,
                    :post => { :body => "", :dog_id => @dog }
      response.should render_template("forum_new")
    end
    
    it "should require the right user for editing" do
      person = login_as(:aaron)
      @post.dog.owner.should_not == person
      get :edit, :forum_id => @forum, :topic_id => @topic, :id => @post
      response.should redirect_to(home_url)
    end
    
    it "should allow admins to destroy posts" do
      admin!(@person)
      @person.should be_admin
      lambda do
        delete :destroy, :forum_id => @forum, :topic_id => @topic,
                         :id => @post, :dog_id => @dog
        response.should redirect_to(forum_topic_url(@forum, @topic))
      end.should change(ForumPost, :count).by(-1)
    end
    
    it "should not allow non-admins to destroy posts" do
      login_as :aaron
      delete :destroy, :forum_id => @forum, :topic_id => @topic,
                       :id => @post, :dog_id => @dog
      response.should redirect_to(home_url)
    end
    
    it "should default post author to topic author for topic author's owner" do
      topic = @forum.topics.build(:name => "New topic")
      topic.dog = dogs(:nola)
      topic.save      
      topic.should be_valid
      get :new, :forum_id => @forum, :topic_id => topic
      assigns(:post).dog.should == dogs(:nola)
    end
    
    it "should not default post author if topic's owner is not current user" do
      login_as :aaron
      topic = @forum.topics.build(:name => "New topic")
      topic.dog = dogs(:nola)
      topic.save
      topic.should be_valid
      get :new, :forum_id => @forum, :topic_id => topic
      assigns(:post).dog.should be_nil   
    end
  end
  
  describe "blog posts" do
    integrate_views
  
    before(:each) do
      @person = login_as(:quentin)
      @dog = dogs(:dana)
      @blog   = @dog.blog
      @post   = posts(:blog_post)
    end
  
    it "should have working pages" do
      with_options :blog_id => @blog do |page|
        page.get    :index
        page.get    :new
        page.get    :show,    :id => @post
        page.get    :edit,    :id => @post
        page.post   :create,  :post => { }
        page.put    :update,  :id => @post
        page.delete :destroy, :id => @post
      end
    end
    
    it "should create a blog post" do
      lambda do
        post :create, :blog_id => @blog,
                      :post => { :title => "The post", :body => "The body" }
        response.should redirect_to(blog_post_url(@blog, assigns(:post)))
      end.should change(BlogPost, :count).by(1)
    end
    
    it "should require the right user to show a blog post" do
      person = login_as(:aaron)
      dog = dogs(:max)
      aarons_blog = dog.blog
      quentins_post = @post
      get :show, :blog_id => aarons_blog, :id => quentins_post
      response.should be_redirect
    end
    
    it "should require the right user to create a blog post" do
      login_as :aaron
      post :create, :blog_id => @blog,
                    :post => { :title => "The post", :body => "The body" }
      response.should be_redirect
    end
    
    it "should create the right blog post associations" do
      lambda do
        post :create, :blog_id => @blog,
                      :post => { :title => "The post", :body => "The body" }
        assigns(:post).blog.should == @blog
      end 
    end
    
    it "should render the new template on creation failure" do
      post :create, :blog_id => @blog, :post => {}
      response.should render_template("blog_new")
    end
    
    it "should require the right user for editing" do
      person = login_as(:aaron)
      @post.blog.owner.owner.should_not == person
      get :edit, :blog_id => @blog, :id => @post
      response.should redirect_to(home_url)
    end
    
    it "should require the post being edited to belong to the blog" do
      wrong_blog = blogs(:two)
      wrong_blog.should_not == @blog
      get :edit, :blog_id => wrong_blog, :id => @post
      response.should redirect_to(home_url)      
    end
    
    it "should destroy a post" do
      delete :destroy, :blog_id => @blog, :id => @post
      @post.should_not exist_in_database
      response.should redirect_to(blog_tab_url(@blog))
    end
    
    it "should require the right user for destroying" do
      person = login_as(:aaron)
      @post.blog.owner.owner.should_not == person
      delete :destroy, :blog_id => @blog, :id => @post
      response.should redirect_to(home_url)
    end
  end
end