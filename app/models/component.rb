class Component < ApplicationRecord
  has_many :component_instances, dependent: :destroy
  belongs_to :category
end
