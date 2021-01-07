# frozen_string_literal: true

# Instances of a data source with concrete account credentials.
class SourceInstance < Instance
  belongs_to :source
  has_many :instance_associations, dependent: :destroy
  has_many :widget_instances, through: :instance_associations
  has_many :record_links, dependent: :destroy
  has_many :rules, dependent: :destroy

  after_create :set_meta, :add_to_scheduler
  after_update :update_callbacks
  before_destroy :remove_from_scheduler

  validate :validate_configuration, if: :configuration_changed?

  # serialize :options, Array if Rails.env.development?

  # Retrieves the refresh interval from this instance's source Hooks class.
  # @return [String] The refresh interval as a time duration string
  def refresh_interval
    @refresh_interval ||= source.hooks_class.refresh_interval
  end

  # Sets the `title` and `options` metadata for this instance.
  # @return [Object]
  def set_meta
    # FIXME: Fetching title and options in different methods prevents data reuse. Add new hook metadata for sources.
    hooks = hook_instance
    self.options = hooks.list_sub_resources.map { |option| { uid: option[0], display: option[1] } }
    self.title = hooks.default_title
  rescue StandardError => e
    Rails.logger.error "[set_meta] #{e.message}"
    errors.add(:configuration, e.message)
  end

  # Run updates for metadata and re-schedule the instance.
  # @return [SourceInstance]
  def update_callbacks
    config_changed = saved_change_to_attribute?('configuration')
    set_meta if config_changed
    update_scheduler if config_changed
  end

  # Validate the current configuration against the source's `validate_configuration` hook.
  # @return [Object] Whatever the source returns on successful validation.
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

  # Instantiates the Hooks class for this instance's source.
  # @return [Object] A new instance of the corresponding source's Hooks class.
  def hook_instance
    # TODO: Use memoization here, or possible stale issues?
    source.hooks_class.new(id, configuration)
  end

  def add_to_scheduler
    DataRefresher.schedule(source_instance: self)
  end

  # Re-schedule the instance.
  def update_scheduler
    DataRefresher.unschedule(self)
    DataRefresher.schedule(source_instance: self)
  end

  def remove_from_scheduler
    DataRefresher.unschedule(self)
  # Check for runtime issues that would prevent a refresh.
  # Unlikely that these occur, but in case the user meddles with the database, or for DX during development.
  # @return [Integer] The parsed refresh_interval
  # @raise [RuntimeError] If any of the preconditions fail.
  def validate_setup
    raise RuntimeError, "instance #{id} does not have an associated source, aborting." if source.nil?
    raise RuntimeError, "Could not instantiate hooks class of engine #{source.name}" if source.hooks_class.nil?

    Rufus::Scheduler.parse(refresh_interval)
  rescue ArgumentError => e
    raise RuntimeError, "Faulty refresh interval of #{source.name}: #{e.message}"
  end

  # Validates if the given group and sub-resources are present on this instance.
  # @param [String] group_id  Requested group schema, must be implemented by this instance's source.
  # @param [Array<String>] sub_resources Requested sub-resources of this instance, within the given group schema.
  def validate_fetch_arguments(group_id:, sub_resources:)
    unless source.groups.pluck('slug').include? group_id
      raise ArgumentError, "Invalid group_id #{group_id} for #{source.name}"
    end

    # TODO: Refactor to SourceInstanceOption class or similar.
    # FIXME: Add check to validate that a sub-resource is in the given group.
    # Requires sources to add a `group` key to their `list_sub_resources` implementation.
    invalid_options = sub_resources.difference options.map { |opt| opt['uid'] }
    unless invalid_options.empty?
      raise ArgumentError, "Invalid sub-resources for #{source.name} instance #{id}: #{invalid_options}"
    end

    if configuration.empty?
      raise ArgumentError, "Configuration for instance #{id} of #{source.name} is empty, aborting."
    end
  end
end
