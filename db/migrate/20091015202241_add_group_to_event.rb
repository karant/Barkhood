class AddGroupToEvent < ActiveRecord::Migration
  def self.up
    add_column    :events, :group_id, :integer, :options => "CONSTRAINTS fk_event_group REFERENCES groups(id)"
  end

  def self.down
    remove_column :events, :group_id
  end
end
