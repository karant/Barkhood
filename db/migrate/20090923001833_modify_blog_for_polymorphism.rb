class ModifyBlogForPolymorphism < ActiveRecord::Migration
  def self.up
    add_column :blogs, :owner_id, :integer
    add_column :blogs, :owner_type, :string
    Blog.find(:all).each do |blog|
      blog.owner_type = "Person"
      blog.owner_id = blog.person_id
      blog.save!
    end
    remove_column :blogs, :person_id
  end
 
  def self.down
    add_column :blogs, :person_id, :integer
    Blog.find(:all).each do |blog|
      blog.person_id = blog.owner_id
      blog.save!
    end
    remove_column :blogs, :owner_id
    remove_column :blogs, :owner_type
  end
end
