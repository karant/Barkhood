module GalleriesHelper
  def parent_path(parent)
    case parent.class.to_s
      when 'Dog'
        dog_path(parent, :anchor => 'tGalleries')
      when 'Group'
        group_path(parent, :anchor => 'tGalleries')
    end
  end
end
