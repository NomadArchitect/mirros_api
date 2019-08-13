module GroupSchemas
  class WeatherOwm < ApplicationRecord
    validates :type, presence: true
    has_one :record_link, as: :recordable, dependent: :destroy
    has_many :entries,
             class_name: 'GroupSchemas::WeatherOwmEntry',
             dependent: :delete_all,
             autosave: true
  end
end
