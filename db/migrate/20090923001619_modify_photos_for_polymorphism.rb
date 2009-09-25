class ModifyPhotosForPolymorphism < ActiveRecord::Migration
  def self.up
    add_column :photos, :owner_id, :integer
    add_column :photos, :owner_type, :string
    Photo.find(:all).each do |photo|
      photo.owner_id = photo.person_id
      photo.owner_type = "Person"
      photo.save!
    end
    remove_column :photos, :person_id
  end
 
  def self.down
    add_column :photos, :person_id, :integer
    Photo.find(:all).each do |photo|
      photo.person_id = photo.owner_id
      photo.save!
    end
    remove_column :photos, :owner_id
    remove_column :photos, :owner_type
  end
end
