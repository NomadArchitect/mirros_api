class CalendarResource < RecordableResource
  model_name 'GroupSchemas::Calendar'
  attributes :name, :description, :events, :uid

  def events
    @model.events.sort_by(&:dtstart).as_json
  end
end
