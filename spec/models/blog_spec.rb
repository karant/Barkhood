require File.dirname(__FILE__) + '/../spec_helper'

describe Blog do
  it "should have many posts" do
    Blog.new.posts.should be_a_kind_of(Array)
  end
  
  describe "dog" do
    it "should be itself on dog's blog" do
      blogs(:one).dog.should == dogs(:dana)
    end
    
    it "should be group owner on group's blog" do
      blogs(:group).dog.should == dogs(:dana)
    end
  end
  
  describe "person" do
    it "should be dog's owner" do
      blogs(:one).person.should == people(:quentin)
    end
    
    it "should be group owner's owner" do
      blogs(:group).person.should == people(:quentin)
    end
  end
end
