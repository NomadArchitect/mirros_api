module GroupSchemas
  class ReminderItem < ApplicationRecord
    belongs_to :reminder_list
  end
end

