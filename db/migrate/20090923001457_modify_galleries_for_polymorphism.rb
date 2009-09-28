class ModifyGalleriesForPolymorphism < ActiveRecord::Migration
  def self.up
#    add_column :galleries, :owner_id, :integer
#    add_column :galleries, :owner_type, :string
    remove_column :galleries, :dog_id
  end
 
  def self.down
    add_column :galleries, :dog_id, :integer
    remove_column :galleries, :owner_id
    remove_column :galleries, :owner_type
  end
end
