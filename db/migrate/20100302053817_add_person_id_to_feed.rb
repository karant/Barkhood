class AddPersonIdToFeed < ActiveRecord::Migration
  def self.up
    add_column  :feeds, :person_id, :integer, :options => "CONSTRAINTS fk_feed_person REFERENCES people(id)"
    Feed.find(:all).each do |feed|
      feed.update_attribute(:person_id, feed.dog.owner_id)
    end
  end

  def self.down
    remove_column :feeds, :person_id
  end
end
