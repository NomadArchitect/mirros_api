class SourceInstance < Instance
  belongs_to :source
  has_many :instance_associations, dependent: :destroy
  has_many :widget_instances, through: :instance_associations
  has_many :record_links, dependent: :destroy

  after_create :set_meta, :add_to_scheduler
  after_update :update_callbacks
  before_destroy :remove_from_scheduler

  validate :validate_configuration, if: :configuration_changed?

  # serialize :options, Array if Rails.env.development?

  def refresh_interval
    "#{source_id.camelize}::Hooks".safe_constantize.refresh_interval
  end

  def set_meta
    # FIXME: Fetching title and options in different methods prevents data reuse. Add new hook metadata for sources.
    hooks = hook_instance
    self.options = hooks.list_sub_resources.map { |option| { uid: option[0], display: option[1] } }
    self.title = hooks.default_title
  rescue StandardError => e
    Rails.logger.error "[set_meta] #{e.message}"
    errors.add(:configuration, e.message)
  end

  def update_callbacks
    config_changed = saved_change_to_attribute?('configuration')
    set_meta if config_changed
    update_scheduler if config_changed
  end

  def validate_configuration
    unless hook_instance.configuration_valid?
      errors.add(:configuration, 'invalid parameters')
    end
  rescue RuntimeError => e
    errors.add(:configuration, e.message)
  end

  private

  def hook_instance
    hooks = "#{source_id.camelize}::Hooks".safe_constantize
    raise "could not initialize #{source_id.camelize}::Hooks" if hooks.nil?

    begin
      hooks.new(id, configuration)
    rescue StandardError => e
      raise e.message
    end
  end

  def add_to_scheduler
    DataRefresher.schedule(self)
  end

  def update_scheduler
    DataRefresher.unschedule(self)
    DataRefresher.schedule(self)
  end

  def remove_from_scheduler
    DataRefresher.unschedule(self)
  end

end
