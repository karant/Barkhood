class ModifyBlogForPolymorphism < ActiveRecord::Migration
  def self.up
    add_column :blogs, :owner_id, :integer
    add_column :blogs, :owner_type, :string
    remove_column :blogs, :dog_id
  end
 
  def self.down
    add_column :blogs, :dog_id, :integer
    remove_column :blogs, :owner_id
    remove_column :blogs, :owner_type
  end
end
