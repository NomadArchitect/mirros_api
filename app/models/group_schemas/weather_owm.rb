class GroupSchemas::WeatherOwm < ApplicationRecord
  validates_presence_of :type
  has_one :record_link, as: :recordable, dependent: :destroy
end
