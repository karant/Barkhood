class Connection < ActiveRecord::Base
  extend ActivityLogger
  extend PreferencesHelper
  
  belongs_to :dog
  belongs_to :contact, :class_name => "Dog", :foreign_key => "contact_id"
  has_many :activities, :foreign_key => "item_id", :dependent => :destroy,
                        :conditions => "item_type = 'Connection'"
  validates_presence_of :dog_id, :contact_id
  
  # Status codes.
  ACCEPTED  = 0
  REQUESTED = 1
  PENDING   = 2
  
  # Accept a connection request (instance method).
  # Each connection is really two rows, so delegate this method
  # to Connection.accept to wrap the whole thing in a transaction.
  def accept
    Connection.accept(dog_id, contact_id)
  end
  
  def breakup
    Connection.breakup(dog_id, contact_id)
  end
  
  class << self
  
    # Return true if the dogs are (possibly pending) connections.
    def exists?(dog, contact)
      not conn(dog, contact).nil?
    end
    
    alias exist? exists?
  
    # Make a pending connection request.
    def request(dog, contact, send_mail = nil)
      if send_mail.nil?
        send_mail = !global_prefs.nil? && global_prefs.email_notifications? && contact.owner.connection_notifications?
      end
      if dog == contact or Connection.exists?(dog, contact)
        nil
      else
        transaction do
          create(:dog => dog, :contact => contact, :status => PENDING)
          create(:dog => contact, :contact => dog, :status => REQUESTED)
        end
        if send_mail
          # The order here is important: the mail is sent *to* the contact,
          # so the connection should be from the contact's point of view.
          connection = conn(contact, dog)
          PersonMailer.deliver_connection_request(connection)
        end
        true
      end
    end
  
    # Accept a connection request.
    def accept(dog, contact)
      transaction do
        accepted_at = Time.now
        accept_one_side(dog, contact, accepted_at)
        accept_one_side(contact, dog, accepted_at)
      end
      # Exclude the first admin to prevent everyone's feed from
      # filling up with new registrants.
      # unless [dog, contact].include?(dog.find_first_admin)
      log_activity(conn(dog, contact))
      # end
    end
    
    def connect(dog, contact, send_mail = nil)
      transaction do
        request(dog, contact, send_mail)
        accept(dog, contact)
      end
      conn(dog, contact)
    end
  
    # Delete a connection or cancel a pending request.
    def breakup(dog, contact)
      transaction do
        destroy(conn(dog, contact))
        destroy(conn(contact, dog))
      end
    end
  
    # Return a connection based on the dog and contact.
    def conn(dog, contact)
      find_by_dog_id_and_contact_id(dog, contact)
    end
    
    def accepted?(dog, contact)
      conn(dog, contact).status == ACCEPTED
    end
    
    def connected?(dog, contact)
      exist?(dog, contact) and accepted?(dog, contact)
    end
    
    def pending?(dog, contact)
      exist?(dog, contact) and conn(contact,dog).status == PENDING
    end
  end
  
  private
  
  class << self
    # Update the db with one side of an accepted connection request.
    def accept_one_side(dog, contact, accepted_at)
      conn = conn(dog, contact)
      conn.update_attributes!(:status => ACCEPTED,
                              :accepted_at => accepted_at)
    end
  
    def log_activity(conn)
      activity = Activity.create!(:item => conn, :dog => conn.dog)
      add_activities(:activity => activity, :dog => conn.dog)
      add_activities(:activity => activity, :dog => conn.contact)
    end
  end
end
