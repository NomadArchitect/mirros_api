class DataRefresher
  # TODO: Clean this up and document methods once we reach a stable API.
  def self.schedule_all
    instances = SourceInstance.all

    instances.each do |source_instance|
      schedule(source_instance)
      sleep 5 # Wait between schedules to avoid parallel refreshes
    end
  end

  # FIXME: Refactor to smaller method, maybe convert class methods to instance.
  # Maybe raise errors if preconditions fail and rescue once with log message
  def self.schedule(source_instance)
    source = source_instance.source

    if source.nil?
      Rails.logger.warn "instance #{source_instance.id} does not have an associated source, aborting."
      return
    end

    if source_instance.configuration.empty?
      Rails.logger.warn "Configuration for instance #{source_instance.id} of source #{source.name} is empty, aborting scheduling."
      return
    end

    source_hooks = "#{source.name.camelize}::Hooks".safe_constantize
    if source_hooks.nil?
      Rails.logger.error "Could not instantiate hooks class of engine #{source.name}"
      return
    end

    begin
      Rufus::Scheduler.parse(source_hooks.refresh_interval)
    rescue ArgumentError => e
      Rails.logger.error "Faulty refresh interval of #{source.name}: #{e.message}"
      return
    end

    job_tag = tag_instance(source.name, source_instance.id)
    job_instance = Rufus::Scheduler.s.schedule_interval source_hooks.refresh_interval,
                                                        timeout: '5m',
                                                        overlap: false,
                                                        tag: job_tag do |job|
      unless StateCache.online
        Rails.logger.info "[DataRefresher] Skipping #{source.name} instance #{source_instance.id}, System is offline"
        next
      end
      job_block(source_instance, job, source_hooks)
    end

    source_instance.update(job_id: job_instance.job_id)
    Rails.logger.info "scheduled #{job_tag}"
  end

  # Removes the refresh job for a given SourceInstance from the central schedule.
  def self.unschedule(source_instance)
    tag = tag_instance(source_instance.source.name, source_instance.id)
    Rufus::Scheduler.s.jobs(tag: tag).each(&:unschedule)
    Rails.logger.info "unscheduled job with tag #{tag}"
  end

  def self.tag_instance(source_name, source_instance_id)
    "#{source_name}--#{source_instance_id}"
  end

  # @param [SourceInstance] source_instance
  # @param [Object] job
  # @param [Object] source_hooks
  def self.job_block(source_instance, job, source_hooks)
    # Ensure we're not working with a stale connection
    ActiveRecord::Base.connection.verify!(0) unless ActiveRecord::Base.connected?
    associations = source_instance.instance_associations
    sub_resources = associations.map { |assoc| assoc.configuration['chosen'] }
                                .flatten
                                .uniq
    source_hooks_instance = source_hooks.new(source_instance.id,
                                             source_instance.configuration)

    associations.pluck('group_id').uniq.each do |group|
      # TODO: Specify should_update hook to determine if a SourceInstance needs
      #   to be refreshed at all (e. g. by testing HTTP status - 304 or etag)
      # source_hooks_instance.should_update(group, sub_resources)

      ActiveRecord::Base.transaction do
        begin
          recordables = source_hooks_instance.fetch_data(group, sub_resources)
        rescue StandardError => e
          Rails.logger.error "Error during refresh of #{source_instance.source} instance #{source_instance.id}:
            #{e.message}\n#{e.backtrace.join("\n")}"
          # Delay the next run on failures
          job.next_time = Time.now.utc + Rufus::Scheduler.parse(source_hooks.refresh_interval) * 2
          next
        end
        recordables.each do |recordable|
          recordable.save!
          next unless recordable.record_link.nil?

          source_instance.record_links <<
            RecordLink.create(recordable: recordable, group: Group.find(group))
        end
        source_instance.last_refresh = job.last_time.to_s
        source_instance.save
      end
    end
  rescue StandardError => e
    Rails.logger.error e.message
  ensure
    ActiveRecord::Base.connection_pool.release_connection
  end
end
