# frozen_string_literal: true

module GroupSchemas
  # Base model for public transport data schema.
  class PublicTransport < ApplicationRecord
    validates :type, presence: true
    has_one :record_link, as: :recordable, dependent: :destroy
    has_many :departures,
             class_name: 'PublicTransportDeparture',
             dependent: :delete_all,
             autosave: true
  end
end
