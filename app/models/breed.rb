class Breed < ActiveRecord::Base
  has_many  :dogs
  
  validates_presence_of   :name
  validates_uniqueness_of :name
end
