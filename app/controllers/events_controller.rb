class EventsController < ApplicationController

  # before_filter :in_progress unless test?
  before_filter :login_required
  before_filter :load_event, :except => [:index, :new, :create]
  before_filter :load_date, :only => [:index, :show]
  before_filter :authorize_show, :only => :show
  before_filter :authorize_change, :only => [:edit, :update]
  before_filter :authorize_destroy, :only => :destroy
  before_filter :authorize_attend, :only => :attend
  before_filter :load_dogs, :only => [:new, :edit, :show, :create, :update, :index]
  before_filter :load_privacies, :only => [:new, :edit, :create, :update]
  
  def index
    @month_events = Event.monthly_events(@date).person_events(current_person)
    unless filter_by_day?
      @events = @month_events
    else
      @events = Event.daily_events(@date).person_events(current_person)
    end
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @events }
    end
  end

  def show
    @month_events = Event.monthly_events(@date).person_events(current_person)
    @attendees = @event.attendees.paginate(:page => params[:page], 
                                           :per_page => RASTER_PER_PAGE)
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @event }
    end
  end

  def new
    @event = Event.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @event }
    end
  end

  def edit
  end

  def create
    @group = Group.find(params[:group_id]) if params[:group_id]
    @event = if @group
               @group.events.build(params[:event])
             else
               Event.new(params[:event])
             end
    @event.privacy = params[:event][:privacy] if Event::PRIVACY.values.include?(params[:event][:privacy].to_i)
    @event.dog = current_person.dogs.find(params[:event][:dog_id])

    respond_to do |format|
      if @event.save
        flash[:notice] = 'Event was successfully created.'
        format.html { redirect_to(@event) }
        format.xml  { render :xml => @event, :status => :created, :location => @event }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @event.update_attributes(params[:event])
        flash[:notice] = 'Event was successfully updated.'
        format.html { redirect_to(@event) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @event.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @event.destroy

    respond_to do |format|
      format.html { redirect_to(events_url) }
      format.xml  { head :ok }
    end
  end

  def attend
    if @event.attend(@dog)
      flash[:notice] = "#{@dog.name} is now attending this event."
      redirect_to @event
    else
      flash[:error] = "#{@dog.name} can only attend this event once."
      redirect_to @event
    end
  end

  def unattend
    @dog = current_person.dogs.find(params[:dog_id])
    if @event.unattend(@dog)
      flash[:notice] = "#{@dog.name} is no longer attending this event."
      redirect_to @event
    else
      flash[:error] = "#{@dog.name} is not attending this event."
      redirect_to @event
    end
  end

  private
    
    def in_progress
      flash[:notice] = "Work on this feature is in progress."
      redirect_to home_url
    end
  
    def authorize_show
      if  (@event.only_contacts? and
          not (current_person.dogs.any?{|dog| @event.dog.contact_ids.include?(dog.id)})) or
          (@event.only_group? and
          not (current_person.dogs.any?{|dog| Membership.accepted?(dog, @event.group)})) and
          not (current_person?(@event.dog.owner) or current_person.admin?)
        redirect_to home_url 
      end
    end
    
    def authorize_attend
      @dog = current_person.dogs.find(params[:dog_id])
      if ((@event.only_contacts? and !@event.dog.contacts.include?(@dog)) or
          (@event.only_group? and !Membership.accepted?(@dog, @event.group))) and
         @event.dog != @dog
        redirect_to home_url 
      end
    end
  
    def authorize_change
      redirect_to home_url unless current_person?(@event.dog.owner)
    end

    def authorize_destroy
      can_destroy = current_person?(@event.dog.owner) || current_person.admin?
      redirect_to home_url unless can_destroy
    end

    def load_date
      if @event
        @date = @event.start_time
      else
        now = Time.now
        year = (params[:year] || now.year).to_i
        month = (params[:month] || now.month).to_i
        day = (params[:day] || now.mday).to_i
        @date = DateTime.new(year,month,day)
      end
    rescue ArgumentError
      @date = Time.now
    end

    def filter_by_day?
      !params[:day].nil?
    end

    def load_event
      @event = Event.find(params[:id])
    end

    def load_dogs
      if params[:group_id]
        @group = Group.find(params[:group_id])
        @dogs = current_person.dogs.reject{|dog| !Membership.accepted?(dog, @group)}
      elsif !@event.blank? && !@event.group.blank?
        @group = @event.group
        @dogs = current_person.dogs.reject{|dog| !Membership.accepted?(dog, @group)}
      else
        @dogs = current_person.dogs
      end
    end
  
    def load_privacies
      @privacies = if params[:group_id]
                     [["Public", Event::PRIVACY[:public]],["Group members only", Event::PRIVACY[:group]]]
                   else
                     [["Public", Event::PRIVACY[:public]],["Me and my contacts", Event::PRIVACY[:contacts]]]
                   end
    end
end
