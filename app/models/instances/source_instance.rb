# frozen_string_literal: true

# Instances of a data source with concrete account credentials.
class SourceInstance < Instance
  belongs_to :source
  has_many :instance_associations, dependent: :destroy
  has_many :widget_instances, through: :instance_associations
  has_many :record_links, dependent: :destroy
  has_many :rules, dependent: :destroy

  after_create :set_meta, :schedule
  after_update :update_callbacks
  before_destroy :unschedule

  validate :validate_configuration, if: :configuration_changed?

  # Retrieves the refresh interval from this instance's source Hooks class.
  # @return [String] The refresh interval as a time duration string
  def refresh_interval
    @refresh_interval ||= source.hooks_class.refresh_interval
  end

  # Refreshes all active sub-resources for this instance.
  def refresh
    # TODO: Specify should_update hook to determine if a SourceInstance needs
    #   to be refreshed at all (e. g. by testing HTTP status - 304 or etag)
    # source_hooks_instance.should_update(group, sub_resources)
    unless instance_associations.any?
      Rails.logger.info("Skipped refresh for #{interval_job_tag}: no associated WidgetInstance")
      return
    end

    # Ensure we're not working with a stale connection
    # ActiveRecord::Base.connection.verify! unless ActiveRecord::Base.connected?
    ActiveRecord::Base.transaction do
      build_group_map.each do |group_id, sub_resources|
        update_data(group_id: group_id, sub_resources: sub_resources.to_a)
      end
      update!(last_refresh: Time.now.utc)
    end
    # ensure
    # Avoid hogging stale connections since we're outside the main Rails process.
    # ActiveRecord::Base.connection_pool.release_connection
  end

  # Sets the `title` and `options` metadata for this instance.
  # @return [Object]
  def set_meta
    # FIXME: Fetching title and options in different methods prevents data reuse.
    # Add new hook metadata for sources.
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
    return unless saved_change_to_attribute?('configuration')

    set_meta
    update_scheduler
  end

  # Validate the current configuration against the source's `validate_configuration` hook.
  # @return [Object] Whatever the source returns on successful validation.
  def validate_configuration
    hook_instance.validate_configuration
    # FIXME: Remove once all sources are migrated to this hook so they can provide user feedback
  rescue NoMethodError => _e
    Rails.logger.warn ActiveSupport::Deprecation.warn(
      "Please implement a `validate_configuration` hook for #{source.name}"
    )
    errors.add(:configuration, 'invalid parameters') unless hook_instance.configuration_valid?
  rescue StandardError => e
    Rails.logger.error "[#{__method__} #{source_id}] #{e.message}"
    errors.add(:configuration, e.message)
  end

  # Schedules a periodic refresh for this source instance and saves the job's id.
  # @return [Hash<String, Array<String>] The schedule configuration.
  def schedule
    validate_setup

    Sidekiq.set_schedule "refresh_#{interval_job_tag}",
                         {
                           interval: refresh_interval,
                           class: RefreshSourceInstanceJob,
                           args: id # TODO: GlobalID serialization doesn't seem to work properly
                         }
  rescue RuntimeError, ArgumentError => e
    Rails.logger.error e.message
  end

  # Removes the refresh job for this instance from the central schedule.
  # @return [Object]
  def unschedule
    Rufus::Scheduler.s.jobs(tag: interval_job_tag).each(&:unschedule)
    Rails.logger.info "unscheduled job with tag #{interval_job_tag}"
  end

  # Fetch and save data for given group schema and sub-resource(s) of this instance.
  # @param [String] group_id The group schema to fetch.
  # @param [Array<String>] sub_resources UIDs of the sub-resources that should be fetched.
  # @param [TrueClass|FalseClass] validate Whether group and sub_resources should be validated.
  def update_data(group_id:, sub_resources:, validate: true)
    validate_fetch_arguments(group_id: group_id, sub_resources: sub_resources) if validate

    recordables = hook_instance.fetch_data(group_id, sub_resources)
    recordables.each do |recordable|
      recordable.save!
      next unless recordable.record_link.nil?

      # New recordable, create the link.
      record_links << RecordLink.new(recordable: recordable, group: Group.find(group_id))
    end
  end

  # Validates if the given group and sub-resources are present on this instance.
  # @param [String] group_id  Requested group schema, must be implemented by this instance's source.
  # @param [Array<String>] sub_resources Requested sub-resources within the given group schema.
  # @raise [SIArgumentError] given group or sub-resources are invalid
  # @raise [ArgumentError] The instance has no configuration.
  # @return [nil]
  def validate_fetch_arguments(group_id:, sub_resources:)
    unless source.groups.pluck('slug').include? group_id
      raise SourceInstanceArgumentError.new 'group_id',
                                            "Invalid group_id #{group_id} for #{source.name}"
    end

    # TODO: Refactor to SourceInstanceOption class or similar.
    # FIXME: Add check to validate that a sub-resource is in the given group.
    # Requires sources to add a `group` key to their `list_sub_resources` implementation.
    # TODO: Remove to_s once all source instance option returns are validated to be string pairs.
    invalid_options = sub_resources.difference(options.map { |opt| opt['uid'].to_s })
    unless invalid_options.empty?
      raise SourceInstanceArgumentError.new 'configuration',
                                            "Invalid sub-resources for #{source.name} instance #{id}: #{invalid_options}"
    end

    return if configuration.present?

    raise ArgumentError "Empty configuration for #{source.name} instance #{id}, aborting."
  end

  private

  # Instantiates the Hooks class for this instance's source.
  # @return [Object] A new instance of the corresponding source's Hooks class.
  def hook_instance
    # TODO: Use memoization here, or possible stale issues?
    source.hooks_class.new(id, configuration)
  end

  # Returns a unique Rufus scheduler tag for this instance. Instance variable is lazy on purpose.
  # for every SourceInstance instance.
  # @return [String] The tag for this source instance's refresh job.
  def interval_job_tag
    @interval_job_tag ||= "#{source.name}--#{id}"
  end

  # Builds a map of all sub-resources currently selected in this instance's InstanceAssociations.
  # @return [Hash{String => Set}] All selected sub-resources of this instance, keyed by group_id.
  def build_group_map
    instance_associations.each_with_object({}) do |assoc, memo|
      memo[assoc.group_id] = Set.new if memo[assoc.group_id].nil?
      memo[assoc.group_id].merge assoc.configuration['chosen']
    end
  end

  # Re-schedule the instance.
  def update_scheduler
    unschedule
    schedule
  end

  # Check for runtime issues that would prevent a refresh.
  # Unlikely that these occur, but in case the user meddles with the database, or for DX.
  # @return [Integer] The parsed refresh_interval
  # @raise [RuntimeError] If any of the preconditions fail.
  def validate_setup
    raise "instance #{id} does not have an associated source, aborting." if source.nil?
    raise "Could not instantiate hooks class of engine #{source.name}" if source.hooks_class.nil?

    Rufus::Scheduler.parse(refresh_interval)
  rescue ArgumentError => e
    raise "Faulty refresh interval of #{source.name}: #{e.message}"
  end
end
