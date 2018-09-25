class SourceInstance < Instance
  belongs_to :source
  has_many :instance_associations, dependent: :destroy
  has_many :widget_instances, through: :instance_associations
  has_many :record_links, dependent: :destroy

  before_update :set_title, if: :configuration_changed?
  validate :validate_configuration, if: :configuration_changed?

  def options
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

    errors.add(:configuration, 'invalid parameters') unless hook_instance.configuration_valid?
  end

  def set_title
    self.title = hook_instance.default_title
  end

  private

  def hook_instance
    hooks = "#{source_id.capitalize}::Hooks".safe_constantize
    hooks&.new(id, configuration)
    JSONAPI::Exceptions::InternalServerError.new(e) if hooks.nil?
  end
end
