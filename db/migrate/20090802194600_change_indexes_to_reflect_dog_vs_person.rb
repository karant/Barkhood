class ChangeIndexesToReflectDogVsPerson < ActiveRecord::Migration
  def self.up
    add_index "activities", ["dog_id"], :name => "index_activities_on_dog_id" 
    add_index "blogs", ["dog_id"], :name => "index_blogs_on_dog_id"
    add_index "connections", ["dog_id", "contact_id"], :name => "index_connections_on_dog_id_and_contact_id"
    add_index "feeds", ["dog_id", "activity_id"], :name => "index_feeds_on_dog_id_and_activity_id"
    add_index "page_views", ["dog_id", "created_at"], :name => "index_page_views_on_dog_id_and_created_at"
    add_index "photos", ["dog_id"], :name => "index_photos_on_dog_id"
  end

  def self.down
    remove_index "activities", ["dog_id"] 
    remove_index "blogs", ["dog_id"]
    remove_index "connections", ["dog_id", "contact_id"]
    remove_index "feeds", ["dog_id", "activity_id"]
    remove_index "page_views", ["dog_id", "created_at"]
    remove_index "photos", ["dog_id"]
  end
end
