class SearchesController < ApplicationController
  include ApplicationHelper

  before_filter :login_required

  def index
    
    redirect_to(home_url) and return if params[:q].nil?
    
    query = params[:q].strip.inspect
    model = strip_admin(params[:model])
    page  = params[:page] || 1

    unless %(Dog Group Message ForumPost).include?(model)
      flash[:error] = "Invalid search"
      redirect_to home_url and return
    end

    if query.blank?
      @search  = [].paginate
      @results = []
    else
      filters = {}
      if model == "Dog" and current_person.admin?
        # Find all people, including deactivated and email unverified.
        model = "AllDog"
      elsif model == "Message"
        filters['recipient_id'] = current_person.dog_ids
      end
      @search = Ultrasphinx::Search.new(:query => query, 
                                        :filters => filters,
                                        :page => page,
                                        :class_names => model)
      @search.run
      @results = @search.results  
      if model == "AllDog"
        # Convert to dogs so that the routing works.
        @results.map!{ |dog| Dog.find(dog) }
      end
      if model == "Group"
        @results = @results.reject{ |group| group.hidden?}
      end      
    end
  rescue Ultrasphinx::UsageError
    flash[:error] = "Invalid search query"
    redirect_to searches_url(:q => "", :model => params[:model])
  end
  
  def address
    @address = params[:address]
    location = Geokit::Geocoders::MultiGeocoder.geocode(@address)
    conditions = params[:breed_id] ? ["breed_id = ?", params[:breed_id]] : []
    
    @dogs = Dog.mostly_active.paginate(:all, :conditions => conditions, :include => [:breed], :origin => @address, :within => params[:within], :order => 'distance', :page => params[:page], :per_page => RASTER_PER_PAGE)
    @dog_breeds = @dogs.group_by(&:breed)
    
    @map = GMap.new("map_div")
    @map.control_init(:large_map => true,:map_type => true)
    @map.center_zoom_init([location.lat, location.lng], 15)
    
    markers = []
    @dogs.each do |dog|
      markers << GMarker.new([dog.lat, dog.lng], :title => dog.name, :description => render_to_string(:partial => 'dogs/dog_link', :object => dog), :info_window => render_to_string(:partial => 'dogs/dog_info', :object => dog))    
    end
    clusterer = Clusterer.new(markers, :max_visible_markers => 1, :min_markers_per_cluster => 2)
    @map.overlay_init clusterer
    
    respond_to do |format|
      format.html # address.html.erb
      format.xml  { render :xml => @dogs }
    end
  rescue Geokit::Geocoders::GeocodeError
    flash[:error] = "Incorrect address"
    redirect_to dogs_path
  end
  
  private
    
    # Strip off "Admin::" from the model name.
    # This is needed for, e.g., searches in the admin view
    def strip_admin(model)
      model.split("::").last
    end
end
