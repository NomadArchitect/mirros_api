class InstanceAssociation < ApplicationRecord
  attribute :configuration
  belongs_to :widget_instance
  belongs_to :source_instance
end
