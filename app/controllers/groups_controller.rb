class GroupsController < ApplicationController
  before_filter :login_required
  before_filter :group_owner, :only => [:edit, :update, :destroy,
    :new_photo, :save_photo, :delete_photo]
  before_filter :load_date, :only => :show   
  
  def index
    @groups = Group.not_hidden(params[:page])
 
    respond_to do |format|
      format.html
    end
  end
 
  def show
    @group = Group.find(params[:id])
    @parent = @group
    num_contacts = Dog::MAX_DEFAULT_CONTACTS
    @members = @group.dogs
    @some_members = @members[0...num_contacts]
    if logged_in?    
      @pending_requests = @group.pending_requests
      @blog = @group.blog
      @posts = @group.blog.posts.paginate(:page => params[:page])
      @galleries = @group.galleries.paginate(:page => params[:page])  
      @dogs = current_person.dogs.reject{|d| !Membership.accepted?(d, @group)}
      @month_events = @group.events.monthly_events(@date)
      unless filter_by_day?
        @events = @month_events
      else
        @events = Event.daily_events(@date).person_events(current_person)
      end      
    end
    group_redirect_if_not_public
  end
 
  def new
    @group = Group.new
 
    respond_to do |format|
      format.html
    end
  end
 
  def edit
    @group = Group.find(params[:id])
  end
 
  def create
    @group = Group.new(params[:group])
    @group.owner = current_person.dogs.find(params[:group][:dog_id])
 
    respond_to do |format|
      if @group.save
        flash[:notice] = 'Group was successfully created.'
        format.html { redirect_to(group_path(@group)) }
      else
        format.html { render :action => "new" }
      end
    end
  end
 
  def update
    @group = Group.find(params[:id])
 
    respond_to do |format|
      if @group.update_attributes(params[:group])
        flash[:notice] = 'Group was successfully updated.'
        format.html { redirect_to(group_path(@group)) }
      else
        format.html { render :action => "edit" }
      end
    end
  end
 
  def destroy
    @group = Group.find(params[:id])
    @group.destroy
 
    respond_to do |format|
      flash[:notice] = 'Group was successfully deleted.'
      format.html { redirect_to(groups_path()) }
    end
  end
  
  def join
    @group = Group.find(params[:id])
    current_person.dogs.find(params[:dog_id]).groups << @group
    respond_to do |format|
      flash[:notice] = 'Joined to group.'
      format.html { redirect_to(group_path(@group)) }
    end
  end
  
  def leave
    @group = Group.find(params[:id])
    if current_person.dogs.find(params[:dog_id]).groups.include?(@group)
      flash[:notice] = 'You have left the group.'
      current_person.dogs.find(params[:dog_id]).groups.delete(@group)
    end
    respond_to do |format|
      format.html { redirect_to(group_path(@group)) }
    end
  end
  
  def members
    @group = Group.find(params[:id])
    @members = @group.dogs.paginate(:page => params[:page],
                                          :per_page => RASTER_PER_PAGE)
    @pending = @group.pending_requests.paginate(:page => params[:page],
                                          :per_page => RASTER_PER_PAGE)
    group_redirect_if_not_public
  end
  
  def photos
    @group = Group.find(params[:id])
    @photos = @group.photos
    respond_to do |format|
      format.html
    end
  end
  
  def new_photo
    @photo = Photo.new
 
    respond_to do |format|
      format.html
    end
  end
  
  def save_photo
    group = Group.find(params[:id])
    if params[:photo].nil?
      # This is mainly to prevent exceptions on iPhones.
      flash[:error] = "Your browser doesn't appear to support file uploading"
      redirect_to(edit_group_path(group)) and return
    end
    if params[:commit] == "Cancel"
      flash[:notice] = "You have canceled the upload"
      redirect_to(edit_group_path(group)) and return
    end
    
    group_data = { :group => group,
                    :primary => group.photos.empty? }
    @photo = Photo.new(params[:photo].merge(group_data))
    
    respond_to do |format|
      if @photo.save
        flash[:success] = "Photo successfully uploaded"
        if group.owner == current_person
          format.html { redirect_to(edit_group_path(group)) }
        else
          format.html { redirect_to(group_path(group)) }
        end
      else
        format.html { render :action => "new_photo" }
      end
    end
  end
  
  def delete_photo
    @group = Group.find(params[:id])
    @photo = Photo.find(params[:photo_id])
    @photo.destroy
    flash[:success] = "Photo deleted for group '#{@group.name}'"
    respond_to do |format|
      format.html { redirect_to(edit_group_path(@group)) }
    end
  end
  
  private
  
  def group_owner
    redirect_to home_url unless current_person == Group.find(params[:id]).owner.owner
  end
  
  def group_redirect_if_not_public
    respond_to do |format|
      if @group.public? or @group.private? or current_person.admin?
          format.html
      elsif @group.owner?(current_person) or (@group.hidden? and @group.people.include?(current_person))
        format.html
      else
        format.html { redirect_to(groups_path) }
      end
    end
  end

  def load_date
    now = Time.now
    year = (params[:year] || now.year).to_i
    month = (params[:month] || now.month).to_i
    day = (params[:day] || now.mday).to_i
    @date = DateTime.new(year,month,day)
    rescue ArgumentError
      @date = Time.now
  end

  def filter_by_day?
    !params[:day].nil?
  end  
end
