class AddIdentityUrlToPeople < ActiveRecord::Migration
  def self.up
    add_column    :people, :identity_url, :string
  end

  def self.down
    remove_column :people, :identity_url
  end
end
