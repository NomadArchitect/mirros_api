class InstanceAssociation < ApplicationRecord
  belongs_to :widget_instance
  belongs_to :source_instance
end
