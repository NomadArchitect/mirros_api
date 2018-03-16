class Service < ApplicationRecord
  belongs_to :provider, class_name: 'Widget', foreign_key: 'id'
end
