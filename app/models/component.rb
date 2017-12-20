class Component < ApplicationRecord
  has_many :component_instances, dependent: :destroy
  has_and_belongs_to_many :groups
  has_and_belongs_to_many :categories
end
