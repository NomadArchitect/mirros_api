module GroupSchemas
  class PublicTransport < ApplicationRecord
    validates_presence_of :type
    has_one :record_link, as: :recordable, dependent: :destroy
    has_many :departures, class_name: 'PublicTransportDeparture', dependent: :delete_all, autosave: true
  end
end
