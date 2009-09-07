class ConnectionsController < ApplicationController
  
  before_filter :login_required, :setup
  before_filter :authorize_view, :only => :index
  before_filter :authorize_person, :only => [:edit, :update, :destroy]
  before_filter :redirect_for_inactive, :only => [:edit, :update]
  
  # Show all the contacts for a person.
  def index
    @contacts = @dog.contacts.paginate(:page => params[:page],
                                          :per_page => RASTER_PER_PAGE)
  end
  
  def show
    # We never use this, but render "" for the bots' sake.
    render :text => ""
  end
  
  def edit
    @contact = @connection.contact
  end
  
  def create
    @dog = Dog.find(params[:dog_id])
    @contact = Dog.find(params[:contact_id])

    respond_to do |format|
      if Connection.request(@dog, @contact)
        flash[:notice] = 'Connection request sent!'
        format.html { redirect_to(home_url) }
      else
        # This should only happen when people do something funky
        # like friending themselves.
        flash[:notice] = "Invalid connection"
        format.html { redirect_to(home_url) }
      end
    end
  end

  def update
    
    respond_to do |format|
      contact = @connection.contact
      name = contact.name
      case params[:commit]
      when "Accept"
        @connection.accept
        flash[:notice] = %(Accepted connection with
                           <a href="#{dog_url(contact)}">#{name}</a>)
      when "Decline"
        @connection.breakup
        flash[:notice] = "Declined connection with #{name}"
      end
      format.html { redirect_to(home_url) }
    end
  end

  def destroy
    @dog = Dog.find(params[:dog_id])
    @connection.breakup
    
    respond_to do |format|
      flash[:success] = "Ended connection with #{@connection.contact.name}"
      format.html { redirect_to( dog_connections_url(@dog)) }
    end
  end

  private

    def setup
      # Connections have same body class as profiles.
      @body = "profile"
    end

    def authorize_view
      @dog = Dog.find(params[:dog_id])
      unless (current_person?(@dog.owner) or
              Connection.connected_with_person?(@dog, current_person))
        redirect_to home_url
      end
    end
  
    # Make sure the current person is correct for this connection.
    def authorize_person
      @connection = Connection.find(params[:id],
                                    :include => [:dog, :contact])
      unless current_person?(@connection.dog.owner)
        flash[:error] = "Invalid connection."
        redirect_to home_url
      end
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "Invalid or expired connection request"
      redirect_to home_url
    end
    
    # Redirect if the target dog is inactive.
    # Suppose Alice sends Bob a connection request, but then the admin 
    # deactivates Alice.  We don't want Bob to be able to make the connection.
    def redirect_for_inactive
      unless @connection.contact.active?
        flash[:error] = "Invalid connection request: dog profile deactivated"
        redirect_to home_url
      end
    end

end
