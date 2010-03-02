class Feed < ActiveRecord::Base
  belongs_to :activity
  belongs_to :dog
  belongs_to :person
end
