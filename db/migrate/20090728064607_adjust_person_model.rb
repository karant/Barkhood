class AdjustPersonModel < ActiveRecord::Migration
  def self.up
    remove_column :people, :name
    remove_column :people, :description
    remove_column :people, :last_contacted_at    
    remove_column :people, :forum_posts_count
    remove_column :people, :blog_post_comments_count
    remove_column :people, :wall_comments_count
    remove_column :people, :avatar_id
    remove_column :people, :identity_url
    
    add_column    :people, :address, :string
    add_column    :people, :lat, :float
    add_column    :people, :lng, :float
  end

  def self.down
    add_column :people, :name, :string
    add_column :people, :description, :text
    add_column :people, :last_contacted_at, :datetime
    add_column :people, :forum_posts_count, :integer
    add_column :people, :blog_post_comments_count, :integer
    add_column :people, :wall_comments_count, :integer
    add_column :people, :avatar_id, :integer
    add_column :people, :identity_url, :string
    
    remove_column :people, :address
    remove_column :people, :lat
    remove_column :people, :lng
  end
end
