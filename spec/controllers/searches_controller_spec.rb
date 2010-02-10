require File.dirname(__FILE__) + '/../spec_helper'

# Return a list of system processes.
def processes
  process_cmd = case RUBY_PLATFORM
                when /djgpp|(cyg|ms|bcc)win|mingw/ then 'tasklist /v'
                when /solaris/                     then 'ps -ef'
                else
                  'ps aux'
                end
  `#{process_cmd}`
end

# Return true if the search daemon is running.
def testing_search?
  processes.include?('searchd')
end

describe SearchesController do

  before(:each) do
    login_as :quentin
    @preference = Preference.find(:first)
  end

  describe "Dog searches" do
    integrate_views

    it "should require login" do
      logout
      get :index, :q => "", :model => "Dog"
      response.should redirect_to(login_url)
    end
    
    it "should redirect for an invalid model" do
      get :index, :q => "foo", :model => "AllDog"
      response.should redirect_to(home_url)
    end

    it "should return empty for a blank query" do
      get :index, :q => " ", :model => "Dog"
      response.should be_success
      assigns(:results).should == [].paginate
    end
    
    it "should return empty for a nil query" do
      get :index, :q => nil, :model => "Dog"
      response.should be_redirect
      response.should redirect_to(home_url)
    end
  
    it "should return empty for a 'wildcard' query" do
      get :index, :q => "*", :model => "Dog"
      assigns(:results).should == [].paginate
    end

    it "should search by name" do
      get :index, :q => "dana", :model => "Dog"
      assigns(:results).should == [dogs(:dana)].paginate
    end
    
    it "should search by description" do
      get :index, :q => "I'm Dana", :model => "Dog"
      assigns(:results).should == [dogs(:dana)].paginate
    end
    
    describe "as a normal user" do
      
      it "should not return deactivated dogs" do
        deactivated_dog = dogs(:deactivated)
        deactivated_dog.should be_deactivated
        get :index, :q => "deactivated", :model => "Dog"
        assigns(:results).should_not contain(deactivated_dog)
      end
      
#      it "should not return email unverified users" do
#        @preference.email_verifications = true
#        @preference.save!
#        @preference.reload.email_verifications.should == true
#        get :index, :q => "unverified", :model => "Dog"
#        assigns(:results).should == [].paginate
#      end
      
    end
    
    describe "as an admin" do
      integrate_views
      
      before(:each) do
        login_as :admin
      end

# TBD

      it "should return deactivated users" do
        deactivated_dog = dogs(:deactivated)
        deactivated_dog.should be_deactivated
        get :index, :q => "deactivated", :model => "Dog"
        assigns(:results).should contain(deactivated_dog)
      end
      
#      it "should return email unverified users" do
#        @preference.email_verifications = true
#        @preference.save!
#        @preference.reload.email_verifications.should == true
#        get :index, :q => "unverified", :model => "Dog"
#        assigns(:results).should contain(people(:email_unverified))
#      end

      it "should search by name" do
        get :index, :q => "dana", :model => "Dog"
        assigns(:results).should == [dogs(:dana)].paginate
      end
    end
    
    describe "by address" do
      it "should require login" do
        logout
        get :address, :address => "4188 Justin Way, Sacramento CA", :within => "2"
        response.should redirect_to(login_url)
      end
      
      it "should search by correct address" do
        get :address, :address => "4188 Justin Way, Sacramento CA", :within => "2"
        response.should be_success
        assigns(:dogs).should contain(dogs(:dana))
        assigns(:dogs).should_not contain(dogs(:max))
        assigns(:map).should_not be_nil
      end
      
      it "should rescue bad address searches" do
        get :address, :address => "Address or City", :within => "2"  
        response.should be_redirect
      end
    end
  end
  
  describe "Message searches" do
    
    before(:each) do
      @message = communications(:sent_to_dana)
    end

    it "should search by subject" do
      get :index, :q => @message.subject, :model => "Message"
      assigns(:results).should contain(@message)
    end
    
    it "should search by content" do
      get :index, :q => @message.content, :model => "Message"
      assigns(:results).should contain(@message)      
    end
    
    it "should find only messages sent to logged-in user" do
      invalid_message = communications(:sent_to_max)
      get :index, :q => invalid_message.subject, :model => "Message"
      assigns(:results).should_not contain(invalid_message)
    end
    
    it "should not find trashed messages" do
      trashed_message = communications(:sent_to_dana_from_parker_and_trashed)
      get :index, :q => trashed_message.subject, :model => "Message"
      assigns(:results).should_not contain(trashed_message)      
    end
  end
  
  describe "Forum post searches" do
    integrate_views
    
    before(:each) do
      @post = posts(:forum)
    end
        
    it "should search by post body" do
      get :index, :q => @post.body, :model => "ForumPost"
      assigns(:results).should contain(@post)
    end
    
    it "should not raise errors due to finding blog posts" do
      # With STI, it's easy to include blog posts by accident.
      # When Ultrasphinx tries to use ForumPost on a blog post id,
      # it raises an ActiveRecord::RecordNotFound error.
      lambda do
        get :index, :q => posts(:blog_post).body, :model => "ForumPost"
      end.should_not raise_error(ActiveRecord::RecordNotFound)
    end
        
    it "should search by topic name" do
      get :index, :q => @post.topic.name, :model => "ForumPost"
      assigns(:results).should contain(@post)
    end
    
    it "should render with a post div" do
      get :index, :q => @post.body, :model => "ForumPost"
      response.should have_tag("div[class='forum']")
    end
    
    it "should render with a topic link" do
      topic = @post.topic
      get :index, :q => topic.name, :model => "ForumPost"
      url = forum_topic_path(topic.forum, topic, :anchor => "post_#{@post.id}")
      response.should have_tag("a[href=?]", url)
    end
  end
  
  describe "error handling" do
    it "should catch Ultrasphinx::UsageError exceptions" do
      invalid_query = "foo@bar"
      get :index, :q => invalid_query, :model => "Dog"
      response.should be_redirect
      response.should redirect_to(searches_url(:q => "", :model => "Dog"))
    end
  end
  
end if testing_search?