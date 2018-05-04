class SourceInstanceResource < JSONAPI::Resource
  after_create :add_to_scheduler
  after_update :update_scheduler
  after_remove :remove_from_scheduler
  attributes :title, :configuration
  has_one :source
  has_many :widget_instances, through: :instance_associations
end

def add_to_scheduler
  DataRefresher.schedule(@model)
end

def update_scheduler
  DataRefresher.unschedule(@model)
  DataRefresher.schedule(@model)
end

def remove_from_scheduler
  DataRefresher.unschedule(@model)
end
