require File.dirname(__FILE__) + '/../../spec_helper'

describe "/dogs/show.html.erb" do
    
  before(:each) do
    @controller.params[:controller] = "dogs"
    @person = login_as(:quentin)
    @dog = dogs(:dana)
    @dog.description = "Foo *bar*"
    assigns[:dog] = @dog
    assigns[:blog] = @dog.blog
    assigns[:posts] = @dog.blog.posts.paginate(:page => 1)
    assigns[:galleries] = @dog.galleries.paginate(:page => 1)
    assigns[:some_contacts] = @dog.some_contacts
    assigns[:common_contacts] = []
    assigns[:dogs] = @person.dogs
    render "/dogs/show.html.erb"
  end

  it "should have the right title" do
    response.should have_tag("h2", /#{@dog.name}/)
  end
  
  it "should have a Markdown-ed description if BlueCloth is present" do
    begin
      BlueCloth.new("used to raise an exeption")
      response.should have_tag("em", "bar")
    rescue NameError
      nil
    end
  end 
end
