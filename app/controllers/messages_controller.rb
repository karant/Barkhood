class MessagesController < ApplicationController

  before_filter :login_required, :setup
  before_filter :authenticate_person, :only => :show

  # GET /messages
  def index
    @person = current_person
    @messages = @person.received_messages(params[:page])
    respond_to do |format|
      format.html { render :template => "messages/index" }
    end
  end

  # GET /messages/sent
  def sent
    @person = current_person
    @messages = @person.sent_messages(params[:page])
    respond_to do |format|
      format.html { render :template => "messages/index" }
    end
  end
  
  # GET /messages/trash
  def trash
    @person = current_person
    @messages = @person.trashed_messages(params[:page])
    respond_to do |format|
      format.html { render :template => "messages/index" }
    end    
  end

  def show
    @message.mark_as_read if current_person?(@message.recipient.owner)
    respond_to do |format|
      format.html
    end
  end

  def new    
    @message = Message.new
    @recipient = Dog.find(params[:dog_id])

    respond_to do |format|
      format.html
    end
  end

  def reply
    original_message = Message.find(params[:id])
    @dog = original_message.sender.owner == current_person ? original_message.sender : original_message.recipient
    @recipient = original_message.other_dog(@dog)
    @message = Message.unsafe_build(:parent_id    => original_message.id,
                                    :subject      => original_message.subject,
                                    :sender       => @dog,
                                    :recipient    => @recipient)

    # @recipient = not_current_person(original_message)
    respond_to do |format|
      format.html { render :action => "new" }
    end    
  end

  def create
    @dog = current_person.dogs.find(params[:message][:sender_id])
    @message = Message.new(params[:message])
    @recipient = Dog.find(params[:dog_id])
    @message.sender    = @dog
    @message.recipient = @recipient
    if reply?
      @message.parent = Message.find(params[:message][:parent_id])
      redirect_to home_url and return unless @message.valid_reply?
    end
  
    respond_to do |format|
      if !preview? and @message.save
        flash[:success] = 'Message sent!'
        format.html { redirect_to messages_url }
      else
        @preview = @message.content if preview?
        format.html { render :action => "new" }
      end
    end
  end

  def destroy
    @message = Message.find(params[:id])
    if @message.trash(current_person)
      flash[:success] = "Message trashed"
    else
      # This should never happen...
      flash[:error] = "Invalid action"
    end
  
    respond_to do |format|
      format.html { redirect_to messages_url }
    end
  end
  
  def undestroy
    @message = Message.find(params[:id])
    if @message.untrash(current_person)
      flash[:success] = "Message restored to inbox"
    else
      # This should never happen...
      flash[:error] = "Invalid action"
    end
    respond_to do |format|
      format.html { redirect_to messages_url }
    end
  end

  private
  
    def setup
      @body = "messages"
    end
  
    def authenticate_person
      @message = Message.find(params[:id])
      unless (current_person == @message.sender.owner or
              current_person == @message.recipient.owner)
        redirect_to login_url
      end
    end
        
    def reply?
      not params[:message][:parent_id].nil?
    end
    
    # Return the proper recipient for a message.
    # This should not be the current person in order to allow multiple replies
    # to the same message.
    def not_current_person(message)
      message.sender == current_person ? message.recipient : message.sender
    end

    def preview?
      params["commit"] == "Preview"
    end

end
