class SourceInstance < Instance
  belongs_to :source
  has_many :instance_associations, dependent: :destroy
  has_many :widget_instances, through: :instance_associations
  has_many :record_links, dependent: :destroy

  before_create :set_meta
  before_update :set_meta, if: :configuration_changed?
  validate :validate_configuration, if: :configuration_changed?

  serialize :options, Array

  def set_meta
    options = []
    hooks = hook_instance
    begin
      hooks.list_sub_resources.map do |option|
        options << {uid: option[0], display: option[1]}
      end
    rescue RuntimeError => e
      errors.add(:configuration, e.message)
    end
    self.options = options
    self.title = hooks.default_title
  end

  def validate_configuration
    errors.add(:configuration, 'invalid parameters') unless hook_instance.configuration_valid?
  rescue RuntimeError => e
    errors.add(:configuration, e.message)
  end

  private

  def hook_instance
    hooks = "#{source_id.camelcase}::Hooks".safe_constantize
    raise "could not initialize #{source_id.camelcase}::Hooks" if hooks.nil?

    begin
      hooks.new(id, configuration)
    rescue Exception => e
      raise e.message
    end
  end
end
