class SourceInstance < Instance
  belongs_to :source
  has_many :instance_associations, dependent: :destroy
  has_many :widget_instances, through: :instance_associations
  has_many :record_links, dependent: :destroy

  before_update :set_title, if: :configuration_changed?

  def set_title
    hooks = "#{source_id.capitalize}::Hooks".safe_constantize
    self.title = hooks.new(configuration).default_title
  end

  def options
    record_links.collect { |record| record.recordable.name } unless record_links.length === 0 #.camelize(:lower)
    if configuration.empty?
      []
    else
      hooks = "#{source_id.capitalize}::Hooks".safe_constantize
      hooks.new(configuration).list_sub_resources #.map { |sub_resource| sub_resource.camelize(:lower) }
    end
  end
end
