class Preference < ActiveRecord::Base
  attr_accessible :app_name, :server_name, :domain, :smtp_server, 
                  :email_notifications, :email_verifications, :analytics,
                  :about, :demo, :whitelist
                  
  validates_presence_of :domain,       :if => :using_email?
  validates_presence_of :smtp_server,  :if => :using_email?
  
  # Can we send mail with the present configuration?
  def can_send_email?
    not (domain.blank? or smtp_server.blank?)
  end
  
  private
  
    def using_email?
      email_notifications? or email_verifications?
    end
end
