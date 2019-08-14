module GroupSchemas
  class Calendar < ApplicationRecord
    validates :type, presence: true
    has_one :record_link, as: :recordable, dependent: :destroy
    has_many :events, class_name: 'CalendarEvent', dependent: :delete_all, autosave: true
  end
end
