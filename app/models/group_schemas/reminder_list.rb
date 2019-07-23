module GroupSchemas
  class ReminderList < ApplicationRecord
    validates_presence_of :type
    has_one :record_link, as: :recordable, dependent: :destroy
    has_many :reminders, class_name: 'ReminderItem', dependent: :delete_all, autosave: true
  end
end
