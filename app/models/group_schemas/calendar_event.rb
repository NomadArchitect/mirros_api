module GroupSchemas
  class CalendarEvent < ApplicationRecord
    belongs_to :calendar
  end
end
