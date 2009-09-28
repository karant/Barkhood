require File.dirname(__FILE__) + '/../spec_helper'

describe PersonMailer do
  
  before(:each) do
    @preferences = preferences(:one)
    @server = @preferences.server_name
    @domain = @preferences.domain
  end
  
  describe "password reminder" do
     before(:each) do
       @person = people(:quentin)
       @email = PersonMailer.create_password_reminder(@person)    
     end
   
     it "should have the right sender" do
       @email.from.first.should == "password-reminder@#{@domain}"
     end
   
     it "should have the right recipient" do
       @email.to.first.should == @person.email
     end
   
     it "should have the unencrypted password in the body" do
       @email.body.should =~ /#{@person.unencrypted_password}/
     end
   end
   
   describe "message notification" do
     before(:each) do
       @message = dogs(:dana).received_messages.first
       @email = PersonMailer.create_message_notification(@message)
     end
   
     it "should have the right sender" do
       @email.from.first.should == "message@#{@domain}"
     end
   
     it "should have the right recipient" do
       @email.to.first.should == @message.recipient.owner.email
     end

     it "should have the right domain in the body" do
        @email.body.should =~ /#{@server}/
     end
   end
   
   describe "connection request" do
     
     before(:each) do
       @dog  = dogs(:dana)
       @contact = dogs(:max)
       Connection.request(@dog, @contact)
       @connection = Connection.conn(@contact, @dog)
       @email = PersonMailer.create_connection_request(@connection)
     end
     
     it "should have the right recipient" do
       @email.to.first.should == @contact.owner.email
     end
     
     it "should have the right requester" do
       @email.body.should =~ /#{@dog.name}/
     end
     
     it "should have a URL to the connection" do
       url = "http://#{@server}/connections/#{@connection.id}/edit"
       @email.body.should =~ /#{url}/
     end
   
     it "should have the right domain in the body" do
        @email.body.should =~ /#{@server}/
     end
     
     it "should have a link to the recipient's preferences" do
       prefs_url = "http://#{@server}"
       prefs_url += "/people/#{@contact.owner.to_param}/edit"
       @email.body.should =~ /#{prefs_url}/
     end
   end
   
   describe "membership public group" do
     before(:each) do
       @group = groups(:public)
       @dog  = dogs(:max)
       Membership.request(@dog, @group)
       @membership = Membership.mem(@dog, @group)
       @email = PersonMailer.create_membership_public_group(@membership)
     end  
     
     it "should have the right recipient" do
       @email.to.first.should == @group.owner.owner.email
     end
     
     it "should have the right requester" do
       @email.body.should =~ /#{@dog.name}/
     end
     
     it "should have a URL to the group" do
       url = "http://#{@server}/groups/#{@group.to_param}/members"
       @email.body.should =~ /#{url}/
     end
   
     it "should have the right domain in the body" do
        @email.body.should =~ /#{@server}/
     end
     
     it "should have a link to the recipient's preferences" do
       prefs_url = "http://#{@server}"
       prefs_url += "/people/#{@group.owner.owner.to_param}/edit"
       @email.body.should =~ /#{prefs_url}/
     end     
   end
   
   describe "membership request" do
     before(:each) do
       @group = groups(:private)
       @dog  = dogs(:max)
       Membership.request(@dog, @group)
       @membership = Membership.mem(@dog, @group)
       @email = PersonMailer.create_membership_request(@membership)
     end  
     
     it "should have the right recipient" do
       @email.to.first.should == @group.owner.owner.email
     end
     
     it "should have the right requester" do
       @email.body.should =~ /#{@dog.name}/
     end
     
     it "should have a URL to the group" do
       url = "http://#{@server}/groups/#{@group.to_param}/members"
       @email.body.should =~ /#{url}/
     end
   
     it "should have the right domain in the body" do
        @email.body.should =~ /#{@server}/
     end
     
     it "should have a link to the recipient's preferences" do
       prefs_url = "http://#{@server}"
       prefs_url += "/people/#{@group.owner.owner.to_param}/edit"
       @email.body.should =~ /#{prefs_url}/
     end     
   end  
   
   describe "membership accepted" do
     before(:each) do
       @group = groups(:private)
       @dog  = dogs(:max)
       Membership.request(@dog, @group)
       @membership = Membership.mem(@dog, @group)
       @membership.accept
       @email = PersonMailer.create_membership_accepted(@membership)
     end  
     
     it "should have the right recipient" do
       @email.to.first.should == @dog.owner.email
     end
     
     it "should have the right requester" do
       @email.body.should =~ /#{@dog.name}/
     end
     
     it "should have a URL to the group" do
       url = "http://#{@server}/groups/#{@group.to_param}"
       @email.body.should =~ /#{url}/
     end
   
     it "should have the right domain in the body" do
        @email.body.should =~ /#{@server}/
     end
     
     it "should have a link to the recipient's preferences" do
       prefs_url = "http://#{@server}"
       prefs_url += "/people/#{@dog.owner.to_param}/edit"
       @email.body.should =~ /#{prefs_url}/
     end     
   end 
   
   describe "invitation notification" do
     before(:each) do
       @group = groups(:private)
       @dog  = dogs(:max)
       Membership.invite(@dog, @group)
       @membership = Membership.mem(@dog, @group)
       @email = PersonMailer.create_invitation_notification(@membership)
     end  
     
     it "should have the right recipient" do
       @email.to.first.should == @dog.owner.email
     end
     
     it "should have the right requester" do
       @email.body.should =~ /#{@dog.name}/
     end
     
     it "should have a URL to the membership" do
       url = "http://#{@server}/memberships/#{@membership.id}/edit"
       @email.body.should =~ /#{url}/
     end
   
     it "should have the right domain in the body" do
        @email.body.should =~ /#{@server}/
     end
     
     it "should have a link to the recipient's preferences" do
       prefs_url = "http://#{@server}"
       prefs_url += "/people/#{@dog.owner.to_param}/edit"
       @email.body.should =~ /#{prefs_url}/
     end     
   end    
   
   describe "invitation accepted" do
     before(:each) do
       @group = groups(:private)
       @dog  = dogs(:max)
       Membership.invite(@dog, @group)
       @membership = Membership.mem(@dog, @group)
       @membership.accept
       @email = PersonMailer.create_invitation_accepted(@membership)
     end  
     
     it "should have the right recipient" do
       @email.to.first.should == @group.owner.owner.email
     end
     
     it "should have the right requester" do
       @email.body.should =~ /#{@dog.name}/
     end
     
     it "should have a URL to the group" do
       url = "http://#{@server}/groups/#{@group.to_param}/members"
       @email.body.should =~ /#{url}/
     end
   
     it "should have the right domain in the body" do
        @email.body.should =~ /#{@server}/
     end
     
     it "should have a link to the recipient's preferences" do
       prefs_url = "http://#{@server}"
       prefs_url += "/people/#{@group.owner.owner.to_param}/edit"
       @email.body.should =~ /#{prefs_url}/
     end     
   end    
   
   describe "blog comment notification" do
     
     before(:each) do
       @comment = comments(:blog_comment)
       @email = PersonMailer.create_blog_comment_notification(@comment)
       @recipient = @comment.commented_dog
       @commenter = @comment.commenter
     end
     
     it "should have the right recipient" do
       @email.to.first.should == @recipient.owner.email
     end
     
     it "should have the right commenter" do
       @email.body.should =~ /#{@commenter.name}/
     end
     
     it "should have a link to the comment" do
       url = "http://#{@server}"
       url += "/blogs/#{@comment.commentable.blog.to_param}"
       url += "/posts/#{@comment.commentable.to_param}"
       @email.body.should =~ /#{url}/
     end
     
     it "should have a link to the recipient's preferences" do
       prefs_url = "http://#{@server}/people/"
       prefs_url += "#{@recipient.owner.to_param}/edit"
       @email.body.should =~ /#{prefs_url}/
     end
   end
   
   describe "wall comment notification" do
     
     before(:each) do
       @comment = comments(:wall_comment)
       @email = PersonMailer.create_wall_comment_notification(@comment)
       @recipient = @comment.commented_dog
       @commenter = @comment.commenter
     end
     
     it "should have the right recipient" do
       @email.to.first.should == @recipient.owner.email
     end
     
     it "should have the right commenter" do
       @email.body.should =~ /#{@commenter.name}/
     end
     
     it "should have a link to the comment" do
       url = "http://#{@server}"
       url += "/dogs/#{@comment.commentable.to_param}#wall"
       @email.body.should =~ /#{url}/
     end
     
     it "should have a link to the recipient's preferences" do
       prefs_url = "http://#{@server}/people/#{@recipient.owner.to_param}/edit"
       @email.body.should =~ /#{prefs_url}/
     end
   end
   
   describe "email verification" do
     
     before(:each) do
       @ev = email_verifications(:one)
       @email = PersonMailer.create_email_verification(@ev)
     end
     
     it "should have the right recipient" do
       @email.to.first.should == @ev.person.email
     end
     
     it "should have the right subject" do
       @email.subject.should == "[Example] Email verification"
     end
     
     it "should have a URL to the verification page" do
       url = "http://#{@server}/people/verify/#{@ev.code}"
       @email.body.should =~ /#{url}/
     end

     it "should have the right server name in the body" do
       @email.body.should =~ /#{@server}/
     end
   end
end