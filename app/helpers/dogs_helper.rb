module DogsHelper
  def message_links(dogs)
    dogs.map { |p| email_link(p)}
  end

  # Return a dog's image link.
  # The default is to display the dog's icon linked to the profile.
  def image_link(dog, options = {})
    link = options[:link] || dog
    image = options[:image] || :icon
    image_options = { :title => h(dog.name), :alt => h(dog.name) }
    unless options[:image_options].nil?
      image_options.merge!(options[:image_options]) 
    end
    link_options =  { :title => h(dog.name) }
    unless options[:link_options].nil?                    
      link_options.merge!(options[:link_options])
    end
    content = image_tag(dog.send(image), image_options)
    # This is a hack needed for the way the designer handled rastered images
    # (with a 'vcard' class).
    if options[:vcard]
      content = %(#{content}#{content_tag(:span, h(dog.name), 
                                                 :class => "fn" )})
    end
    link_to(content, link, link_options)
  end

  # Link to a dog (default is by name).
  def dog_link(text, dog = nil, html_options = nil)
    if dog.nil?
      dog = text
      text = dog.name
    elsif dog.is_a?(Hash)
      html_options = dog
      dog = text
      text = dog.name
    end
    # We normally write link_to(..., dog) for brevity, but that breaks
    # activities_helper_spec due to an RSpec bug.
    link_to(h(text), dog, html_options)
  end

  # Same as dog_link except sets up HTML needed for the image on hover effect
  def dog_link_with_image(text, dog = nil, html_options = nil)
    if dog.nil?
      dog = text
      text = dog.name
    elsif dog.is_a?(Hash)
      html_options = dog
      dog = text
      text = dog.name
    end
    '<span class="imgHoverMarker">' + image_tag(dog.thumbnail) + dog_link(text, dog, html_options) + '</span>'
  end

  def dog_image_hover_text(text, dog, html_options = nil)
    '<span class="imgHoverMarker">' + image_tag(dog.thumbnail) + text + '</span>'
  end
  
  def activated_status(dog)
    dog.deactivated? ? "Activate" : "Deactivate"
  end
  
  def gender_image(dog)
    if dog.gender == 'Female'
      image_tag('female.png', :title => 'Female')
    elsif dog.gender == 'Male'
      image_tag('male.png', :title => 'Male')
    end
  end
  
  private
    
    # Make captioned images.
    def captioned(images, captions)
      images.zip(captions).map do |image, caption|
        markaby do
          image << div { caption }
        end
      end
    end  
end
