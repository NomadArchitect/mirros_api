module GroupSchemas
  class Reminder < ApplicationRecord
    validates_presence_of :type
    has_many :reminder_items, dependent: :delete_all
    belongs_to :source_instance

    attribute :reminders

    def reminders
      self.reminder_items.as_json
    end
  end
end

