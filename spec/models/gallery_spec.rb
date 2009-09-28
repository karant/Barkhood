require File.dirname(__FILE__) + '/../spec_helper'

describe Gallery do
  before(:each) do
    @gallery = galleries(:valid_gallery)
  end

  it "should be valid" do
    @gallery.should be_valid
  end
  
  it "should require person_id" do
    @gallery = galleries(:invalid_gallery)
    @gallery.should_not be_valid
    @gallery.errors.on(:dog_id).should_not be_empty
  end
    
  it "should have a max title length" do
    @gallery.should have_maximum(:title, 255)
  end
  
  it "should have a max description length" do
    @gallery.should have_maximum(:description, 1000)
  end
  
  it "should have many photos" do
    @gallery.photos.should be_kind_of(Array)
  end
  
  it "should have an activity" do
    @gallery = Gallery.unsafe_create(:owner => dogs(:parker))
    Activity.find_by_item_id(@gallery).should_not be_nil
  end
  
  describe "utility methods" do
    it "should determine person/owner" do
      @gallery.person.should == people(:quentin)
      galleries(:group_gallery).person.should == people(:quentin)
    end
  end
end
