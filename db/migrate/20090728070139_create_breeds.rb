class CreateBreeds < ActiveRecord::Migration
  def self.up
    create_table :breeds do |t|
      t.string  :name
      t.timestamps
    end
  end

  def self.down
    drop_table :breeds
  end
end
