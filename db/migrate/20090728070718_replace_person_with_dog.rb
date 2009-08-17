class ReplacePersonWithDog < ActiveRecord::Migration
  def self.up
    remove_column :activities, :person_id
    remove_column :posts, :person_id
    remove_column :blogs, :person_id
    remove_column :connections, :person_id
    remove_column :event_attendees, :person_id
    remove_column :events, :person_id
    remove_column :feeds, :person_id
    remove_column :galleries, :person_id
    remove_column :page_views, :person_id
    remove_column :photos, :person_id
    remove_column :topics, :person_id
    
    add_column    :activities, :dog_id, :integer, :options =>
                    "CONSTRAINTS fk_activity_dog REFERENCES dogs(id)"
    add_column    :posts, :dog_id, :integer, :options =>
                    "CONSTRAINTS fk_post_dog REFERENCES dogs(id)"      
    add_column    :blogs, :dog_id, :integer, :options =>
                    "CONSTRAINTS fk_blog_dog REFERENCES dogs(id)"   
    add_column    :connections, :dog_id, :integer, :options =>
                    "CONSTRAINTS fk_connection_dog REFERENCES dogs(id)" 
    add_column    :event_attendees, :dog_id, :integer, :options =>
                    "CONSTRAINTS fk_event_attendee_dog REFERENCES dogs(id)"     
    add_column    :events, :dog_id, :integer, :options =>
                    "CONSTRAINTS fk_event_dog REFERENCES dogs(id)" 
    add_column    :feeds, :dog_id, :integer, :options =>
                    "CONSTRAINTS fk_feed_dog REFERENCES dogs(id)"         
    add_column    :galleries, :dog_id, :integer, :options =>
                    "CONSTRAINTS fk_gallery_dog REFERENCES dogs(id)"  
    add_column    :page_views, :dog_id, :integer, :options =>
                    "CONSTRAINTS fk_page_view_dog REFERENCES dogs(id)"    
    add_column    :photos, :dog_id, :integer, :options =>
                    "CONSTRAINTS fk_photo_dog REFERENCES dogs(id)"  
    add_column    :topics, :dog_id, :integer, :options =>
                    "CONSTRAINTS fk_topic_dog REFERENCES dogs(id)"   
  end

  def self.down
    remove_column :activities, :dog_id
    remove_column :posts, :dog_id
    remove_column :blogs, :dog_id
    remove_column :connections, :dog_id
    remove_column :event_attendees, :dog_id
    remove_column :events, :dog_id
    remove_column :feeds, :dog_id
    remove_column :page_views, :dog_id
    remove_column :photos, :dog_id    
    remove_column :topics, :dog_id
      
    add_column    :activities, :person_id, :integer
    add_column    :posts, :person_id, :integer
    add_column    :blogs, :person_id, :integer
    add_column    :connections, :person_id, :integer
    add_column    :event_attendees, :person_id, :integer
    add_column    :events, :person_id, :integer
    add_column    :feeds, :person_id, :integer
    add_column    :page_views, :person_id, :integer
    add_column    :photos, :person_id, :integer
    add_column    :topics, :person_id, :integer
  end
end
