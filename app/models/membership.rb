class Membership < ActiveRecord::Base
  extend ActivityLogger
  extend PreferencesHelper
  
  belongs_to :group
  belongs_to :dog
  has_many :activities, :foreign_key => "item_id", :dependent => :destroy
  validates_presence_of :dog_id, :group_id
  
  # Status codes.
  ACCEPTED = 0
  INVITED = 1
  PENDING = 2
  
  # Accept a membership request (instance method).
  def accept
    Membership.accept(dog_id, group_id)
  end
  
  def breakup
    Membership.breakup(dog_id, group_id)
  end
  
  class << self
    
    # Return true if the dog is member of the group.
    def exists?(dog, group)
      not mem(dog, group).nil?
    end
    
    alias exist? exists?
    
    # Make a pending membership request.
    def request(dog, group, send_mail = nil)
      if send_mail.nil?
        send_mail = global_prefs.email_notifications? &&
                    group.owner.owner.connection_notifications?
      end
      if dog.groups.include?(group) or Membership.exists?(dog, group)
        nil
      else
        if group.public? or group.private?
          transaction do
            create(:dog => dog, :group => group, :status => PENDING)
            if send_mail
              membership = dog.memberships.find(:first, :conditions => ['group_id = ?',group])
              PersonMailer.deliver_membership_request(membership)
            end
          end
          if group.public?
            membership = dog.memberships.find(:first, :conditions => ['group_id = ?',group])
            membership.accept
            if send_mail
              PersonMailer.deliver_membership_public_group(membership)
            end
          end
        end
        true
      end
    end
    
    def invite(dog, group, send_mail = nil)
      if send_mail.nil?
        send_mail = global_prefs.email_notifications? &&
                    group.owner.owner.connection_notifications?
      end
      if dog.groups.include?(group) or Membership.exists?(dog, group)
        nil
      else
        transaction do
          create(:dog => dog, :group => group, :status => INVITED)
          if send_mail
            membership = dog.memberships.find(:first, :conditions => ['group_id = ?',group])
            PersonMailer.deliver_invitation_notification(membership)
          end
        end
        true
      end
    end
    
    # Accept a membership request.
    def accept(dog, group)
      transaction do
        accepted_at = Time.now
        accept_one_side(dog, group, accepted_at)
      end
      unless Group.find(group).hidden?
        log_activity(mem(dog, group))
      end
    end
    
    def breakup(dog, group)
      transaction do
        destroy(mem(dog, group))
      end
    end
    
    def mem(dog, group)
      find_by_dog_id_and_group_id(dog, group)
    end
    
    def accepted?(dog, group)
      exist?(dog, group) and mem(dog, group).status == ACCEPTED
    end
    
    def accepted_by_person?(person, group)
      result = false
      person.dogs.each do |dog|
        result = accepted?(dog, group)
        break if result
      end
      return result
    end
    
    def connected?(dog, group)
      exist?(dog, group) and accepted?(dog, group)
    end
    
    def pending?(dog, group)
      exist?(dog, group) and mem(dog,group).status == PENDING
    end
    
    def invited?(dog, group)
      exist?(dog, group) and mem(dog,group).status == INVITED
    end
    
  end
  
  private
  
  class << self
    # Update the db with one side of an accepted connection request.
    def accept_one_side(dog, group, accepted_at)
      mem = mem(dog, group)
      mem.update_attributes!(:status => ACCEPTED,
                              :accepted_at => accepted_at)
    end
  
    def log_activity(membership)
      activity = Activity.create!(:item => membership, :owner => membership.dog)
      add_activities(:activity => activity, :owner => membership.dog)
      activity = Activity.create!(:item => membership, :owner => membership.group)
      add_activities(:activity => activity, :owner => membership.group)
    end
  end  
end
