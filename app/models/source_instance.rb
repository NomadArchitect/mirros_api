# frozen_string_literal: true

# Instances of a data source with concrete account credentials.
class SourceInstance < Instance
  belongs_to :data_source
  has_many :instance_associations, dependent: :destroy
  has_many :widget_instances, through: :instance_associations
  has_many :record_links, dependent: :destroy
  has_many :rules, dependent: :destroy

  after_create :set_meta, :add_to_scheduler
  after_update :update_callbacks
  before_destroy :remove_from_scheduler

  validate :validate_configuration, if: :configuration_changed?

  # serialize :options, Array if Rails.env.development?

  def refresh_interval
    data_source.hooks_class.refresh_interval
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
    hook_instance.validate_configuration
    # FIXME: Remove once all source have migrated to raising on errors so that they can provide user feedback
  rescue NoMethodError => _e
    Rails.logger.warn ActiveSupport::Deprecation.warn("Please implement a `validate_configuration` hook for #{source.name}")
    unless hook_instance.configuration_valid?
      errors.add(:configuration, 'invalid parameters')
    end
  rescue StandardError => e
    Rails.logger.error "[#{__method__} #{source_id}] #{e.message}"
    errors.add(:configuration, e.message)
  end

  private

  def hook_instance
    data_source.hooks_class.new(id, configuration)
  end

  def add_to_scheduler
    DataRefresher.schedule(source_instance: self)
  end

  def update_scheduler
    DataRefresher.unschedule(self)
    DataRefresher.schedule(source_instance: self)
  end

  def remove_from_scheduler
    DataRefresher.unschedule(self)
  end
end
