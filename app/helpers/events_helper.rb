module EventsHelper
  def parent_events_path
    if @group
      group_events_path(@group)
    else
      events_path
    end
  end
end
