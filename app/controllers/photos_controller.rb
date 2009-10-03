class PhotosController < ApplicationController

  before_filter :login_required
  before_filter :get_instance_vars, :except => [ :index ]
  before_filter :correct_user_required,
                :only => [ :edit, :update, :destroy ]
  before_filter :owner_required, :only => [ :set_primary, :set_avatar ]
  before_filter :correct_gallery_required, :only => [:new, :create]
  
  def index
    redirect_to parent_galleries_path
  end
  
  def show
    @photo = Photo.find(params[:id])
  end

  
  def new
    @photo = @gallery.photos.build
    respond_to do |format|
      format.html
    end
  end

  def edit
    @display_photo = @photo
    respond_to do |format|
      format.html
    end
  end

  def create
    if params[:photo].nil?
      # This is mainly to prevent exceptions on iPhones.
      flash[:error] = "Your browser doesn't appear to support file uploading"
      redirect_to gallery_path(Gallery.find(params[:gallery_id])) and return
    end

    photo_data = params[:photo].merge(:created_by => current_person)
    @photo = @gallery.photos.build(photo_data)

    respond_to do |format|
      if @photo.save
        flash[:success] = "Photo successfully uploaded"
        format.html { redirect_to @photo.gallery }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def update
    @photo = Photo.find(params[:id])
    
    respond_to do |format|
      if @photo.update_attributes(params[:photo])
        flash[:success] = "Photo successfully updated"
        format.html { redirect_to(gallery_path(@photo.gallery)) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def destroy
    @gallery = @photo.gallery
    redirect_to parent_galleries_path and return if @photo.nil?
    @photo.destroy
    flash[:success] = "Photo deleted"
    respond_to do |format|
      format.html { redirect_to gallery_path(@gallery) }
    end
  end
  
  def set_primary
    @photo = Photo.find(params[:id])
    if @photo.nil? or @photo.primary?
      redirect_to parent_galleries_path and return
    end
    # This should only have one entry, but be paranoid.
    @old_primary = @photo.gallery.photos.select(&:primary?)
    respond_to do |format|
      if @photo.update_attributes(:primary => true)
        @old_primary.each { |p| p.update_attributes!(:primary => false) }
        format.html { redirect_to(parent_galleries_path) }
        flash[:success] = "Gallery thumbnail set"
      else    
        format.html do
          flash[:error] = "Invalid image!"
          redirect_to home_url
        end
      end
    end
  end
  
  def set_avatar
    @photo = Photo.find(params[:id])
    if @photo.nil? or @photo.avatar?
      redirect_to parent and return
    end
    # This should only have one entry, but be paranoid.
    @old_primary = parent.photos.select(&:avatar?)
  
    respond_to do |format|
      if @photo.update_attributes!(:avatar => true)
        @old_primary.each { |p| p.update_attributes!(:avatar => false) }
        flash[:success] = "Profile photo set"
        format.html { redirect_to parent }
      else    
        format.html do
          flash[:error] = "Invalid image!"
          redirect_to home_url
        end
      end
    end
  end
  
  private
  
    def correct_user_required
      if ( dog? && @gallery.person != current_person ) || ( group? && !( @group.owner?(current_person) || @photo.created_by == current_person))
        redirect_to parent_galleries_path
      end
    end
    
    def correct_gallery_required
      if params[:gallery_id].nil?
        flash[:error] = "You cannot add photo without specifying gallery"
        redirect_to parent_galleries_path
      elsif ( dog? && @gallery.person != current_person ) || ( group? && !( @group.owner?(current_person) || Membership.accepted_by_person?(current_person, @group)))
        flash[:error] = "You cannot add photos to this gallery"
        redirect_to gallery_path(@gallery)
      end
    end
    
    def owner_required
      if ( dog? && @gallery.person != current_person ) || ( group? && !@group.owner?(current_person))
        flash[:error] = "You are not the owner of this " + @gallery.owner.class.to_s.downcase
        redirect_to gallery_path(@gallery)
      end      
    end
  
    def get_instance_vars
      if params[:id]
        @photo = Photo.find(params[:id])
        @gallery = @photo.gallery      
      elsif params[:gallery_id]
        @gallery = Gallery.find(params[:gallery_id])  
      end
      if @gallery
        if dog?
          @dog = @gallery.owner
        elsif group?
          @group = @gallery.owner
        end
      else
        flash[:error] = "Gallery could not be determined"
        redirect_to home_path
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
      @gallery.owner.class.to_s == 'Dog'
    end
    
    def group?
      @gallery.owner.class.to_s == 'Group'
    end
end

