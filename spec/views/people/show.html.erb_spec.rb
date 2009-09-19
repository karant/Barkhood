require File.dirname(__FILE__) + '/../../spec_helper'

describe "/people/show.html.erb" do
    
  before(:each) do
    @controller.params[:controller] = "people"
    @person = login_as(:quentin)
    assigns[:person] = @person
    render "/people/show.html.erb"
  end

  it "should have the right title" do
    response.should have_tag("h2", /Profile/)
  end
  
#  it "should have a Markdown-ed description if BlueCloth is present" do
#    begin
#      BlueCloth.new("used to raise an exeption")
#      response.should have_tag("em", "bar")
#    rescue NameError
#      nil
#    end
#  end 
end
