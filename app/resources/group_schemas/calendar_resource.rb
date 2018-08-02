class CalendarResource < RecordableResource
  model_name 'GroupSchemas::Calendar'
  attributes :name, :description, :events

  def events
    @model.events.as_json(except: %i[uid calendar_id])
  end
end
