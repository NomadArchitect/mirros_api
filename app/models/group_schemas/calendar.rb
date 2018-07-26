module GroupSchemas
  class Calendar < ApplicationRecord
    validates_presence_of :type
    has_many :calendar_events, dependent: :delete_all
    belongs_to :source_instance
  end
end

