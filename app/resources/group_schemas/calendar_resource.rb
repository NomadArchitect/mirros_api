# frozen_string_literal: true

class GroupSchemas::CalendarResource < RecordableResource
  model_name 'GroupSchemas::Calendar'
  attributes :name, :description, :events
  key_type :string

  def events
    @model.events.sort_by(&:dtstart).as_json
  end
end
