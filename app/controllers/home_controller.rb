class HomeController < ApplicationController
  skip_before_filter :require_activation
  
  def index
    @body = "home"
    @topics = Topic.find_recent
    @members = Dog.recent
    if logged_in?
      @feed = current_person.feed
      # @some_contacts = current_person.some_contacts
      # @requested_contacts = current_person.requested_contacts
      @dogs = current_person.dogs
      @requested_memberships = Membership.find(:all, 
          :conditions => ['status = ? AND group_id in (?)', Membership::PENDING, current_person.dogs.each{|d| d.own_group_ids}.flatten.uniq])
    else
      @feed = Activity.global_feed
    end
    
    respond_to do |format|
      format.html
      format.atom
    end  
  end
  
  def tos
    # tos.html.erb
  end

  def privacy
    # privacy.html.erb
  end
end
