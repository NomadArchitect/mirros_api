module GroupSchemas
  class ReminderList < ApplicationRecord
    validates :type, presence: true
    has_one :record_link, as: :recordable, dependent: :destroy
    has_many :reminders, class_name: 'ReminderItem', dependent: :delete_all, autosave: true
  end
end
