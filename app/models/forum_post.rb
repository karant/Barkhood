class ForumPost < Post
  is_indexed :fields => [ 'body' ],
             :conditions => "type = 'ForumPost'",
             :include => [{:association_name => 'topic', :field => 'name'}]

  attr_accessible :body
  
  belongs_to :topic,  :counter_cache => true
  belongs_to :dog, :counter_cache => true
  
  validates_presence_of :body, :dog
  validates_length_of :body, :maximum => 5000
  
  after_create :log_activity
    
  private
  
    def log_activity
      add_activities(:item => self, :dog => dog)
    end
end
