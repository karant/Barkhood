class RenameSexToGender < ActiveRecord::Migration
  def self.up
    rename_column   :dogs, :sex, :gender
  end

  def self.down
    rename_column   :dogs, :gender, :sex
  end
end
