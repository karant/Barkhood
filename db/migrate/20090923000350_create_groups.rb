class CreateGroups < ActiveRecord::Migration
  def self.up
    create_table :groups do |t|
      t.string :name
      t.text :description
      t.integer :mode, :null => false, :default => 0
      t.integer :dog_id
      t.integer :avatar_id

      t.timestamps
    end
  end

  def self.down
    drop_table :groups
  end
end
