class Component < ApplicationRecord
  has_many :component_instances, dependent: :destroy
  has_and_belongs_to_many :groups
  belongs_to :category
end
