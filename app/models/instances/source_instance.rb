class SourceInstance < Instance
  belongs_to :source
  has_many :instance_associations, dependent: :destroy
  has_many :widget_instances, through: :instance_associations
  has_many :record_links, dependent: :destroy

  before_create :set_title
  before_update :set_title, if: :configuration_changed?
  validate :validate_configuration, if: :configuration_changed?

  def options
    # TODO: Return error when offline
    if configuration.empty?
      []
    else
      options = []
      hook_instance.list_sub_resources.map do |option|
        options << { uid: option[0], display: option[1] }
      end
      options
    end
  end

  def validate_configuration
    return if configuration.empty?

    begin
      errors.add(:configuration, 'invalid parameters') unless hook_instance.configuration_valid?
    rescue RuntimeError => e
      errors.add(:configuration, e.message)
    end

  end

  def set_title
    self.title = hook_instance.default_title
  end

  private

  def hook_instance
    hooks = "#{source_id.camelcase}::Hooks".safe_constantize
    raise "could not initialize #{source_id.camelcase}::Hooks" if hooks.nil?

    hooks.new(id, configuration)
  end
end
