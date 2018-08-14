class SourceInstance < Instance
  belongs_to :source
  has_many :instance_associations, dependent: :destroy
  has_many :widget_instances, through: :instance_associations
  has_many :record_links, dependent: :destroy

  before_update :set_title, if: :configuration_changed?

  def options
    record_links.collect { |record| record.recordable.name } unless record_links.length === 0
    if configuration.empty?
      []
    else
      hook_instance.list_sub_resources
    end
  end
  def set_title
    self.title = hook_instance.default_title
  end

  private

  def hook_instance
    hooks = "#{source_id.capitalize}::Hooks".safe_constantize
    hooks.new(id, configuration)
  end
end
