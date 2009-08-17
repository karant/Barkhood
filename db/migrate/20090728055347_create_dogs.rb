class CreateDogs < ActiveRecord::Migration
  def self.up
    create_table :dogs do |t|
      t.integer  :owner_id, :options => "CONSTRAINTS fk_dog_owner REFERENCES people(id)"
      t.string   :name
      t.text     :description
      t.date     :dob
      t.string   :sex
      t.integer  :breed_id, :options => "CONSTRAINTS fk_dog_breed REFERENCES breeds(id)"
      t.datetime :last_contacted_at
      t.integer  :forum_posts_count,           :default => 0,     :null => false
      t.integer  :blog_post_comments_count,    :default => 0,     :null => false
      t.integer  :wall_comments_count,         :default => 0,     :null => false
      t.boolean  :deactivated,                 :default => false, :null => false
      t.integer  :avatar_id
      t.string   :identity_url
      
      t.timestamps
    end
    
    add_index :dogs, [:owner_id], :name => "index_dogs_on_owner_id"    
  end

  def self.down
    drop_table :dogs
      
    remove_index :dogs, [:owner_id]
  end
end
