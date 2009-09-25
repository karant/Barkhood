class ModifyActivitiesForPolymorphism < ActiveRecord::Migration
  def self.up
    add_column :activities, :owner_id, :integer
    add_column :activities, :owner_type, :string
    Activity.find(:all).each do |activity|
      activity.owner_type = "Person"
      activity.owner_id = activity.person_id
      activity.save!
    end
    remove_column :activities, :person_id
  end
 
  def self.down
    add_column :activities, :person_id, :integer
    Activity.find(:all).each do |activity|
      activity.person_id = activity.owner_id
      activity.save!
    end
    remove_column :activities, :owner_id
    remove_column :activities, :owner_type
  end
end
