class GalleriesController < ApplicationController
  before_filter :login_required
  before_filter :get_instance_vars
  before_filter :correct_user_required, :only => [ :edit, :update, :destroy ]
  
  def show
    @body = "galleries"
    @gallery = Gallery.find(params[:id])
    @photos = @gallery.photos.paginate :page => params[:page] 
  end
  
  def index
    @body = "galleries"
    @parent = parent
    @galleries = @parent.galleries.paginate :page => params[:page]
  end
  
  def new
    @gallery = parent.galleries.new
  end
  
  def create
    @dog = current_person.dogs.find(params[:gallery][:dog_id])
    @gallery = parent.galleries.build(params[:gallery])
    respond_to do |format|
      if @gallery.save
        flash[:success] = "Gallery successfully created"
        format.html { redirect_to gallery_path(@gallery) }
      else
        format.html { render :action => "new" }
      end
    end
  end
  
  def edit
    @gallery = Gallery.find(params[:id])
  end
  
  def update
    @gallery = Gallery.find(params[:id])
    respond_to do |format|
      if @gallery.update_attributes(params[:gallery])
        flash[:success] = "Gallery successfully updated"
        format.html { redirect_to gallery_path(@gallery) }
      else
        format.html { render :action => "new" }
      end
    end
  end
  
  def destroy
    if parent.galleries.count == 1
      flash[:error] = "You can't delete the final gallery"
    elsif parent.galleries.find(params[:id]).destroy
      flash[:success] = "Gallery successfully deleted"
    else
      flash[:error] = "Gallery could not be deleted"
    end

    respond_to do |format|
      format.html { redirect_to parent_galleries_path }
    end

  end
 
  private
  
    def correct_user_required
      @gallery = Gallery.find(params[:id])
      if @gallery.nil?
        flash[:error] = "No gallery found"
        redirect_to dog_galleries_path(current_user.dogs.first)
      elsif @gallery.person != current_person
        flash[:error] = "You are not the owner of this gallery"
        redirect_to parent_galleries_path
      end
  end
  
  def get_instance_vars
    if dog?
      @dog = Dog.find(params[:dog_id])
    elsif group?
      @group = Group.find(params[:group_id])
    end
  end
  
  def parent_galleries_path
    if dog?
      dog_galleries_path(parent)
    elsif group?
      group_galleries_path(parent)
    end
  end
  
  def parent
    if dog?
      @dog
    elsif group?
      @group
    end
  end
  
  def dog?
    !params[:dog_id].nil?
  end
  
  def group?
    !params[:group_id].nil?
  end
end
