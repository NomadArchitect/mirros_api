class InstanceAssociation < ApplicationRecord
  attribute :configuration, cast_type: :json
  belongs_to :widget_instance
  belongs_to :source_instance
end
