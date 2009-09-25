class DogsController < ApplicationController
  
  skip_before_filter :admin_warning, :only => [ :show, :update ]
  before_filter :login_required, :only => [ :new, :show, :edit, :update, :create,
                                            :common_contacts ]
  before_filter :correct_user_required, :only => [ :edit, :update ]
  before_filter :setup
  before_filter :get_breeds, :only => [ :new, :edit, :update, :create ]
  
  def index
    @dogs = Dog.mostly_active(params[:page])

    respond_to do |format|
      format.html
    end
  end
  
  def show
    @dog = Dog.find(params[:id])
    unless @dog.active? or current_person.admin? or @dog.owner == current_person
      flash[:error] = "That dog is not active"
      redirect_to home_url and return
    end
    if logged_in?
      @some_contacts = @dog.some_contacts
      page = params[:page]
      @common_contacts = current_person.common_contacts_with(@dog,
                                                             :page => page)
      # Use the same max number as in basic contacts list.
      num_contacts = Dog::MAX_DEFAULT_CONTACTS
      @some_common_contacts = @common_contacts[0...num_contacts]
      @blog = @dog.blog
      @posts = @dog.blog.posts.paginate(:page => params[:page])
      @galleries = @dog.galleries.paginate(:page => params[:page])
      @groups = current_person == @dog.owner ? @dog.groups : @dog.groups_not_hidden
      @some_groups = @groups[0...num_contacts]
      @own_groups = current_person == @dog.owner ? @dog.own_groups : @dog.own_not_hidden_groups
      @some_own_groups = @own_groups[0...num_contacts]
    end
    respond_to do |format|
      format.html
    end
  end

  def new
    @body = "register single-col"
    @dog = current_person.dogs.build

    respond_to do |format|
      format.html
    end
  end

  def create
    @dog = current_person.dogs.build(params[:dog])
    respond_to do |format|
      if @dog.save
        flash[:notice] = "You dog profile has been created."
        format.html { redirect_back_or_default(home_url) }
      else
        @body = "register single-col"
        format.html { render :action => 'new' }
      end
    end
  end

  def edit
    @dog = current_person.dogs.find(params[:id])

    respond_to do |format|
      format.html
    end
  end

  def update
    @dog = current_person.dogs.find(params[:id])
    respond_to do |format|
      if !preview? and @dog.update_attributes(params[:dog])
        flash[:success] = 'Dog profile updated!'
        format.html { redirect_to(@dog) }
      else
        if preview?
          @preview = @dog.description = params[:dog][:description]
        end
        format.html { render :action => "edit" }
      end
    end
  end
  
  def common_contacts
    @dog = Dog.find(params[:id])
    @common_contacts = @dog.common_contacts_with(current_person,
                                                    :page => params[:page])
    respond_to do |format|
      format.html
    end
  end
  
  private

    def setup
      @body = "dog"
    end
    
    def get_breeds
      @breeds = Breed.find(:all)
    end
  
    def correct_user_required
      redirect_to home_url unless current_person.dogs.include? Dog.find(params[:id])
    end
    
    def preview?
      params["commit"] == "Preview"
    end

end
