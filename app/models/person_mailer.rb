class PersonMailer < ActionMailer::Base
  extend PreferencesHelper
  
  def domain
    @domain ||= PersonMailer.global_prefs.domain
  end
  
  def server
    @server_name ||= PersonMailer.global_prefs.server_name
  end
  
  def password_reminder(person)
    from         "password_reminder@#{domain}"
    recipients   person.email
    subject      formatted_subject("Password reminder")
    body         "person" => person
  end
  
  def message_notification(message)
    from         "message@#{domain}"
    recipients   message.recipient.owner.email
    subject      formatted_subject("New message")
    body         "server" => server, "message" => message,
                 "preferences_note" => preferences_note(message.recipient.owner)
  end
  
  def connection_request(connection)
    from         "connection@#{domain}"
    recipients   connection.dog.owner.email
    subject      formatted_subject("Contact request from #{connection.contact.name}")
    body         "server" => server,
                 "connection" => connection,
                 "url" => edit_connection_path(connection),
                 "preferences_note" => preferences_note(connection.dog.owner)
  end
  
  def membership_public_group(membership)
    from "membership@#{domain}"
    recipients membership.group.owner.owner.email
    subject formatted_subject("New member in group #{membership.group.name}")
    body "server" => server,
                 "membership" => membership,
                 "url" => members_group_path(membership.group),
                 "preferences_note" => preferences_note(membership.group.owner.owner)
  end
  
  def membership_request(membership)
    from "membership@#{domain}"
    recipients membership.group.owner.owner.email
    subject formatted_subject("Membership request for group #{membership.group.name}")
    body "server" => server,
                 "membership" => membership,
                 "url" => members_group_path(membership.group),
                 "preferences_note" => preferences_note(membership.group.owner.owner)
  end
  
  def membership_accepted(membership)
    from "membership@#{domain}"
    recipients membership.dog.owner.email
    subject formatted_subject("#{membership.dog.name} has been accepted to join #{membership.group.name}")
    body "server" => server,
                 "membership" => membership,
                 "url" => group_path(membership.group),
                 "preferences_note" => preferences_note(membership.dog.owner)
  end
  
  def invitation_notification(membership)
    from "invitation#{domain}"
    recipients membership.dog.owner.email
    subject formatted_subject("Invitation for #{membership.dog.name} from group #{membership.group.name}")
    body "server" => server,
                 "membership" => membership,
                 "url" => edit_membership_path(membership),
                 "preferences_note" => preferences_note(membership.dog.owner)
  end
  
  def invitation_accepted(membership)
    from "invitation@#{domain}"
    recipients membership.group.owner.owner.email
    subject formatted_subject("#{membership.dog.name} accepted the invitation")
    body "server" => server,
                 "membership" => membership,
                 "url" => members_group_path(membership.group),
                 "preferences_note" => preferences_note(membership.group.owner.owner)
  end  
  
  def blog_comment_notification(comment)
    from         "comment@#{domain}"
    recipients   comment.commented_dog.owner.email
    subject      formatted_subject("New blog comment")
    body         "server" => server, "comment" => comment,
                 "url" => 
                 blog_post_path(comment.commentable.blog, comment.commentable),
                 "preferences_note" => 
                    preferences_note(comment.commented_dog.owner)
  end
  
  def wall_comment_notification(comment)
    from         "comment@#{domain}"
    recipients   comment.commented_dog.owner.email
    subject      formatted_subject("New wall comment")
    body         "server" => server, "comment" => comment,
                 "url" => dog_path(comment.commentable, :anchor => "wall"),
                 "preferences_note" => 
                    preferences_note(comment.commented_dog.owner)
  end
  
  def email_verification(ev)
    from         "email@#{domain}"
    recipients   ev.person.email
    subject      formatted_subject("Email verification")
    body         "server_name" => server,
                 "code" => ev.code
  end
  
  private
  
    # Prepend the application name to subjects if present in preferences.
    def formatted_subject(text)
      name = PersonMailer.global_prefs.app_name
      label = name.blank? ? "" : "[#{name}] "
      "#{label}#{text}"
    end
  
    def preferences_note(person)
      %(To change your email notification preferences, visit http://#{server}/people/#{person.to_param}/edit#email_prefs)
    end
end
