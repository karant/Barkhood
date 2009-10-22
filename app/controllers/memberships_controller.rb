class MembershipsController < ApplicationController
  before_filter :login_required
  before_filter :authorize_person, :only => [:edit, :update, :destroy, :subscribe, :unsubscribe]
  before_filter :check_for_owner_deletion, :only => [:destroy, :unsubscribe]
  
  
  def edit
    @membership = Membership.find(params[:id])
  end
  
  def create
    @group = Group.find(params[:group_id])
 
    respond_to do |format|
      if Membership.request(current_person.dogs.find(params[:dog_id]), @group)
        if @group.public?
          flash[:notice] = "You have joined '#{@group.name}'"
        else
          flash[:notice] = 'Membership request sent!'
        end
        format.html { redirect_to(home_url) }
      else
        # This should only happen when people do something funky
        # like trying to join a group that has a request pending
        flash[:notice] = "Invalid membership"
        format.html { redirect_to(home_url) }
      end
    end
  end
  
  def update
    
    respond_to do |format|
      membership = @membership
      name = membership.group.name
      case params[:commit]
      when "Accept"
        @membership.accept
        PersonMailer.deliver_invitation_accepted(@membership)
        flash[:notice] = %(Accepted membership with
<a href="#{group_path(@membership.group)}">#{name}</a>)
      when "Decline"
        @membership.breakup
        flash[:notice] = "Declined membership for #{name}"
      end
      format.html { redirect_to(home_url) }
    end
  end
  
  def destroy
    @membership = Membership.find(params[:id])
    @dog = @membership.dog
    @membership.breakup
    
    respond_to do |format|
      flash[:success] = "You have left the group #{@membership.group.name}"
      format.html { redirect_to( dog_memberships_url(@dog)) }
    end
  end
  
  def unsubscribe
    @membership = Membership.find(params[:id])
    @membership.breakup
    
    respond_to do |format|
      flash[:success] = "You have unsubscribed '#{@membership.dog.name}' from group '#{@membership.group.name}'"
      format.html { redirect_to(members_group_path(@membership.group)) }
    end
  end
  
  def subscribe
    @membership = Membership.find(params[:id])
    @membership.accept
    PersonMailer.deliver_membership_accepted(@membership)
 
    respond_to do |format|
      flash[:success] = "You have accepted '#{@membership.dog.name}' for group '#{@membership.group.name}'"
      format.html { redirect_to(members_group_path(@membership.group)) }
    end
  end
  
  private
  
  # Make sure the current person is correct for this connection.
    def authorize_person
      @membership = Membership.find(params[:id],
                                    :include => [:dog, :group])
      if !params[:invitation].blank? or params[:action] == 'subscribe' or params[:action] == 'unsubscribe'
        unless current_person?(@membership.group.owner.owner)
          flash[:error] = "Invalid person."
          redirect_to home_url
        end
      else
        unless current_person?(@membership.dog.owner)
          flash[:error] = "Invalid person."
          redirect_to home_url
        end
      end
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Invalid or expired membership request"
      redirect_to home_url
    end
  
    def check_for_owner_deletion
      @membership = Membership.find(params[:id])
      if @membership.group.owner == @membership.dog
        flash[:error] = "You cannot delete membership of the group owner"
        if action_name == 'unsubscribe'
          redirect_to members_group_path(@membership.group)
        else
          redirect_to dog_memberships_path(@membership.dog)
        end
      end
    end
end
