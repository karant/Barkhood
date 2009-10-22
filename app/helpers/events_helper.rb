module EventsHelper
  def parent_events_path
    if @group
      group_events_path(@group)
    else
      events_path
    end
  end
  
  def parent_new_event_path
    if @group
      new_group_event_path(@group)
    else
      new_event_path
    end
  end
end
