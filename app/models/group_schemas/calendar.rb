module GroupSchemas
  class Calendar < ApplicationRecord
    validates_presence_of :type
    has_many :calendar_events, dependent: :delete_all
    attribute :events

    def events
      calendar_events
    end

  end
end

