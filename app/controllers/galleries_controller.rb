class GalleriesController < ApplicationController
  before_filter :login_required
  before_filter :correct_user_required, :only => [ :edit, :update, :destroy ]
  
  def show
    @body = "galleries"
    @gallery = Gallery.find(params[:id])
    @photos = @gallery.photos.paginate :page => params[:page] 
  end
  
  def index
    @body = "galleries"
    @dog = Dog.find(params[:dog_id])
    @galleries = @dog.galleries.paginate :page => params[:page]
  end
  
  def new
    @gallery = Gallery.new
  end
  
  def create
    @dog = current_person.dogs.find(params[:gallery][:dog_id])
    @gallery = @dog.galleries.build(params[:gallery])
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
    @dog = current_person.dogs.find(params[:dog_id])
    if @dog.galleries.count == 1
      flash[:error] = "You can't delete the final gallery"
    elsif @dog.galleries.find(params[:id]).destroy
      flash[:success] = "Gallery successfully deleted"
    else
      flash[:error] = "Gallery could not be deleted"
    end

    respond_to do |format|
      format.html { redirect_to dog_galleries_path(@dog) }
    end

  end
 
  private
  
    def correct_user_required
      @gallery = Gallery.find(params[:id])
      if @gallery.nil?
        flash[:error] = "No gallery found"
        redirect_to dog_galleries_path(current_user.dogs.first)
      elsif @gallery.dog.owner != current_person
        flash[:error] = "You are not the owner of this gallery"
        redirect_to dog_galleries_path(@gallery.dog)
      end
    end
end
