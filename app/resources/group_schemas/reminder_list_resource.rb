module GroupSchemas
  class ReminderListResource < JSONAPI::Resource
    caching

    model_name 'GroupSchemas::ReminderList'
    attributes :name, :description, :reminders

    def reminders
      @model.reminders.as_json(except: %i[uid calendar_id])
    end
  end
end
