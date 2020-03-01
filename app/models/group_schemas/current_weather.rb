# frozen_string_literal: true

module GroupSchemas
  class CurrentWeather < ApplicationRecord
    include UpdateOrInsertable
    UPSERT_ASSOC = :entries
    ID_FIELD = :uid

    validates :type, presence: true
    has_one :record_link, as: :recordable, dependent: :destroy
    has_many :entries,
             class_name: 'GroupSchemas::CurrentWeatherEntry',
             dependent: :delete_all,
             autosave: true
  end
end
