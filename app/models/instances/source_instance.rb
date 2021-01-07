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
    return unless saved_change_to_attribute?('configuration')

    set_meta
    update_scheduler
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

  # Schedules a periodic refresh for this source instance.
  # @return [SourceInstance] The scheduled instance.
  def schedule
    validate_setup

    job_instance = Rufus::Scheduler.s.schedule_interval refresh_interval,
                                                        timeout: '5m',
                                                        overlap: false,
                                                        first_in: :now,
                                                        tag: interval_job_tag do |job|
      if System.online?
        job_block(job: job)
      else
        Rails.logger.info("System offline, skipping #{source.name} instance #{id}")
      end
    end

    # Refresh immediately to ensure we have fresh data, as schedule_interval does not have a first_in parameter.
    #job_instance.call
    # Save the refresh job ID.
    update(job_id: job_instance.job_id)
    Rails.logger.info "scheduled #{interval_job_tag}"
    self
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
  def update_data(group_id:, sub_resources:)
    validate_fetch_arguments(group_id: group_id, sub_resources: sub_resources)

    ActiveRecord::Base.transaction do
      recordables = hook_instance.fetch_data(group_id, sub_resources)
      recordables.each do |recordable|
        recordable.save!
        next unless recordable.record_link.nil?

        # New recordable, create the link.
        record_links << RecordLink.new(recordable: recordable, group: Group.find(group_id))
      end
      update!(last_refresh: Time.now.utc)
    end
  rescue StandardError => e
    ActiveRecord::Base.connection_pool.connections.select { |conn| conn.owner.eql? Thread.current }.first.disconnect!
    raise e
  end

  private

  # Instantiates the Hooks class for this instance's source.
  # @return [Object] A new instance of the corresponding source's Hooks class.
  def hook_instance
    # TODO: Use memoization here, or possible stale issues?
    source.hooks_class.new(id, configuration)
  end

  # Returns a unique Rufus scheduler tag for this instance. Instance variable is lazy as we don't need it
  # for every SourceInstance instance.
  # @return [String] The tag for this source instance's refresh job.
  def interval_job_tag
    @interval_job_tag ||= "#{source.name}--#{id}"
  end

  # Refreshes all active sub-resources for this instance.
  # @param [Rufus::Scheduler::IntervalJob] job The job that calls this block
  def job_block(job:)
    # Ensure we're not working with a stale connection
    unless ActiveRecord::Base.connected?
      ActiveRecord::Base.connection.verify!(0)
    end

    groups = instance_associations.reduce(Hash.new) do |memo, assoc|
      memo[assoc.group_id] = Set.new if memo[assoc.group_id].nil?
      memo[assoc.group_id].add *assoc.configuration['chosen']
      memo
    end

    groups.each do |group_id, sub_resources|
      # TODO: Specify should_update hook to determine if a SourceInstance needs
      #   to be refreshed at all (e. g. by testing HTTP status - 304 or etag)
      # source_hooks_instance.should_update(group, sub_resources)
      update_data(group_id: group_id, sub_resources: sub_resources.to_a)
    rescue StandardError => e
      Rails.logger.error "Error during refresh of #{source} instance #{id}:
            #{e.message}\n#{e.backtrace[0, 3]&.join("\n")}"

      # Delay the next run on failures
      job.next_time = EtOrbi::EoTime.now + (job.interval * 2)
      next
    end
  rescue StandardError => e
    Rails.logger.error e.message
  ensure
    ActiveRecord::Base.connection_pool.release_connection
  end

  # Re-schedule the instance.
  def update_scheduler
    unschedule
    schedule
  end

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
