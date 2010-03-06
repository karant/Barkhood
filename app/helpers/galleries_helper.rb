module GalleriesHelper 
  def parent_galleries_path(parent)
    case parent.class.to_s
      when 'Dog'
        dog_galleries_path(parent)
      when 'Group'
        group_galleries_path(parent)
    end
  end
end
