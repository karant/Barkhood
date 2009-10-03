require File.dirname(__FILE__) + '/../spec_helper'

describe Photo do
  
  before(:each) do
    @filename = "rails.png"
    @person = people(:quentin)
    @dog = dogs(:dana)
    @gallery = galleries(:valid_gallery)
    @image = uploaded_file(@filename, "image/png")
  end
  
  it "should upload successfully" do
    photo = new_photo
    photo.created_by = @person
    photo.should be_valid
  end
  
  it "should be invalid without created_by_id" do
    photo = new_photo
    photo.should_not be_valid
  end
  
  it "should be invalid without gallery_id" do
    @gallery = nil
    photo = new_photo
    photo.created_by = @person    
    photo.should_not be_valid
  end
  
  it "should not have default AttachmentFu errors for an empty image" do
    photo = new_photo(:uploaded_data => nil)
    photo.created_by = @person
    photo.should_not be_valid
    photo.errors.on(:size).should be_nil
    photo.errors.on(:base).should_not be_nil
  end
  
  private
  
    def new_photo(options = {})
      Photo.new({ :uploaded_data => @image,
                  :gallery       => @gallery }.merge(options))
    end
end