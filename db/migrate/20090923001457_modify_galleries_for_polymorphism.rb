class ModifyGalleriesForPolymorphism < ActiveRecord::Migration
  def self.up
    add_column :galleries, :owner_id, :integer
    add_column :galleries, :owner_type, :string
    Gallery.find(:all).each do |gallery|
      gallery.owner_id = gallery.person_id
      gallery.owner_type = "Person"
      gallery.save!
    end
    remove_column :galleries, :person_id
  end
 
  def self.down
    add_column :galleries, :person_id, :integer
    Gallery.find(:all).each do |gallery|
      gallery.person_id = gallery.owner_id
      gallery.save!
    end
    remove_column :galleries, :owner_id
    remove_column :galleries, :owner_type
  end
end
