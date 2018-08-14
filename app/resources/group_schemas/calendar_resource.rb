class CalendarResource < RecordableResource
  model_name 'GroupSchemas::Calendar'
  attributes :name, :description, :events

  def events
    @model.events.sort_by(&:dtstart).as_json(except: %i[uid calendar_id])
  end
end
