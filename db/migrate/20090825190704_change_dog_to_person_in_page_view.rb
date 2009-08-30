class ChangeDogToPersonInPageView < ActiveRecord::Migration
  def self.up
    remove_column   :page_views, :dog_id
    add_column      :page_views, :person_id, :integer, :options => "CONSTRAINTS fk_page_view_person REFERENCES people(id)"
  end

  def self.down
    remove_column   :page_views, :person_id
    add_column      :page_views, :dog_id, :integer, :options => "CONSTRAINTS fk_page_view_dog REFERENCES dogs(id)"    
  end
end
