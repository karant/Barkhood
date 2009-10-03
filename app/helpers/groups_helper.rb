module GroupsHelper
 def group_owner?(person,group)
    person == group.owner.owner
  end
  
  # Return a group's image link.
  # The default is to display the group's icon linked to the profile.
  def image_link(group, options = {})
    link = options[:link] || group
    image = options[:image] || :icon
    image_options = { :title => h(group.name), :alt => h(group.name) }
    unless options[:image_options].nil?
      image_options.merge!(options[:image_options])
    end
    link_options = { :title => h(group.name) }
    unless options[:link_options].nil?
      link_options.merge!(options[:link_options])
    end
    content = image_tag(group.send(image), image_options)
    # This is a hack needed for the way the designer handled rastered images
    # (with a 'vcard' class).
    if options[:vcard]
      content = %(#{content}#{content_tag(:span, h(group.name),
                                                 :class => "fn" )})
    end
    link_to(content, link, link_options)
  end
  
  
  def group_link(text, group = nil, html_options = nil)
    if group.nil?
      group = text
      text = group.name
    elsif group.is_a?(Hash)
      html_options = group
      group = text
      text = group.name
    end
    # We normally write link_to(..., group) for brevity, but that breaks
    # activities_helper_spec due to an RSpec bug.
    link_to(h(text), group, html_options)
  end
  
  # Same as dog_link except sets up HTML needed for the image on hover effect
  def group_link_with_image(text, group = nil, html_options = nil)
    if group.nil?
      group = text
      text = group.name
    elsif group.is_a?(Hash)
      html_options = group
      group = text
      text = group.name
    end
    '<span class="imgHoverMarker">' + image_tag(group.thumbnail) + group_link(text, group, html_options) + '</span>'
  end  
  
  def get_groups_modes
    modes = []
    modes << ["Public",0]
    modes << ["Private",1]
    modes << ["Hidden", 2]
    return modes
  end  
end
