class RemoveNameFromOwner < ActiveRecord::Migration
  def self.up
    remove_column   :people, :name
  end

  def self.down
    add_column      :people, :name, :string
  end
end
