class RemoveOwnerFromPhotos < ActiveRecord::Migration
  def self.up
    add_column    :photos, :created_by_id, :integer
    remove_column :photos, :owner_id
    remove_column :photos, :owner_type
  end

  def self.down
    add_column    :photos, :owner_id, :integer
    add_column    :photos, :owner_type, :string
    remove_column :photos, :created_by_id
  end
end
