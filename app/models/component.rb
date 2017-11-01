class Component < ApplicationRecord
  has_many :component_instances, dependent: :destroy
end
