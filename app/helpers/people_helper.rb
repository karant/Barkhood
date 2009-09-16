module PeopleHelper

  def message_links(people)
    people.map { |p| email_link(p)}
  end

  # Link to a person (default is by name).
  def person_link(text, person = nil, html_options = nil)
    if person.nil?
      person = text
      text = person.name
    elsif person.is_a?(Hash)
      html_options = person
      person = text
      text = person.name
    end
    # We normally write link_to(..., person) for brevity, but that breaks
    # activities_helper_spec due to an RSpec bug.
    link_to(h(text), person, html_options)
  end
  
  def activated_status(person)
    person.deactivated? ? "Activate" : "Deactivate"
  end
end
