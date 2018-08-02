module GroupSchemas
  class ReminderList < ApplicationRecord
    validates_presence_of :type
    has_many :reminders, class_name: 'ReminderItem', dependent: :delete_all
    has_one :record_link, as: :recordable, dependent: :destroy
  end
end
