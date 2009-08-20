class PersonMailer < ActionMailer::Base
  extend PreferencesHelper
  
  def domain
    @domain ||= PersonMailer.global_prefs.domain
  end
  
  def server
    @server_name ||= PersonMailer.global_prefs.server_name
  end
  
  def password_reminder(person)
    from         "Password reminder <password-reminder@#{domain}>"
    recipients   person.email
    subject      formatted_subject("Password reminder")
    body         "person" => person
  end
  
  def message_notification(message)
    from         "Message notification <message@#{domain}>"
    recipients   message.recipient.owner.email
    subject      formatted_subject("New message")
    body         "server" => server, "message" => message,
                 "preferences_note" => preferences_note(message.recipient)
  end
  
  def connection_request(connection)
    from         "Contact request <connection@#{domain}>"
    recipients   connection.dog.owner.email
    subject      formatted_subject("Contact request from #{connection.contact.name}")
    body         "server" => server,
                 "connection" => connection,
                 "url" => edit_connection_path(connection),
                 "preferences_note" => preferences_note(connection.dog)
  end
  
  def blog_comment_notification(comment)
    from         "Comment notification <comment@#{domain}>"
    recipients   comment.commented_dog.owner.email
    subject      formatted_subject("New blog comment")
    body         "server" => server, "comment" => comment,
                 "url" => 
                 blog_post_path(comment.commentable.blog, comment.commentable),
                 "preferences_note" => 
                    preferences_note(comment.commented_dog)
  end
  
  def wall_comment_notification(comment)
    from         "Comment notification <comment@#{domain}>"
    recipients   comment.commented_dog.owner.email
    subject      formatted_subject("New wall comment")
    body         "server" => server, "comment" => comment,
                 "url" => dog_path(comment.commentable, :anchor => "wall"),
                 "preferences_note" => 
                    preferences_note(comment.commented_dog)
  end
  
  def email_verification(ev)
    from         "Email verification <email@#{domain}>"
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
  
    def preferences_note(dog)
      %(To change your email notification preferences, visit http://#{server}/dogs/#{dog.to_param}/edit#email_prefs)
    end
end
