module GroupSchemas
  class WeatherOwm < ApplicationRecord
    validates_presence_of :type
    has_one :record_link, as: :recordable, dependent: :destroy
    has_many :entries, class_name: 'GroupSchemas::WeatherOwmEntry', dependent: :delete_all, autosave: true
  end
end
