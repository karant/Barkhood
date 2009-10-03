# Helpers added to this module are available in both controllers and views.
module SharedHelper

  def current_person?(person)
    logged_in? and person == current_person
  end
  
  # Return true if a dog is connected to (or is) the current person
  def connected_to?(dog)
    current_person?(dog.owner) or Connection.connected_with_person?(dog, current_person)
  end
  
  # Return true if one of current person's dogs is the owner of a group or if member of it
  def is_member_of?(group)
    current_person.dogs.include?(group.owner) or Membership.accepted_by_person?(current_person, group)
  end  
  
  def new_parent_gallery_path(parent)
    case parent.class.to_s
      when 'Dog'
        new_dog_gallery_path(parent)
      when 'Group'
        new_group_gallery_path(parent)
    end
  end
end
