class ReminderListResource < JSONAPI::Resource
  model_name 'GroupSchemas::ReminderList'
  attributes :name, :description, :reminders

  def reminders
    @model.reminders.sort_by(&:creation_date).as_json
  end
end
