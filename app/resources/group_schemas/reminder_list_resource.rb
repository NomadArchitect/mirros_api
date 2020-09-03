class GroupSchemas::ReminderListResource < RecordableResource
  model_name 'GroupSchemas::ReminderList'
  attributes :name, :description, :reminders
  key_type :string

  def reminders
    @model.reminders.sort_by(&:creation_date).as_json
  end
end
