class DataRefresher

  # TODO: Clean this up and document methods once we reach a stable API.
  def self.scheduler
    Rufus::Scheduler.singleton
  end

  def self.schedule_all
    instances = SourceInstance.all

    instances.each do |source_instance|
      schedule(source_instance)
    end
  end

  # FIXME: Refactor to smaller method, maybe convert class methods to instance
  def self.schedule(source_instance)
    s = scheduler
    source = source_instance.source

    if source_instance.configuration.empty?
      Rails.logger.info "Configuration for instance #{source_instance.id} of source #{source.name} is empty, aborting scheduling."
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
    job_instance = s.schedule_interval source_hooks.refresh_interval, tag: job_tag do |job|
      # Skip refresh if the system is offline.
      next unless StateCache.online?

      job_block(source_instance, job, source_hooks)
    end

    source_instance.update(job_id: job_instance.job_id)
    Rails.logger.info "scheduled #{job_tag}"
  end

  # Removes the refresh job for a given SourceInstance from the central schedule.
  def self.unschedule(source_instance)
    s = scheduler
    tag = tag_instance(source_instance.source.name, source_instance.id)
    s.jobs(tag: tag).each(&:unschedule)
    Rails.logger.info "unscheduled job with tag #{tag}"
  end

  def self.tag_instance(source_name, source_instance_id)
    "#{source_name}--#{source_instance_id}"
  end

  def self.job_block(source_instance, job, source_hooks)
    unless ActiveRecord::Base.connected?
      ActiveRecord::Base.connection.verify!(0)
    end

    associations = source_instance.instance_associations
    sub_resources = associations.map { |assoc| assoc.configuration['chosen'] }
                                .flatten
                                .uniq
    source_hooks_instance = source_hooks.new(source_instance.id,
                                             source_instance.configuration)

    associations.pluck('group_id').uniq.each do |group|
      # TODO: Specify should_update hook to determine if a SourceInstance needs
      #   to be refreshed at all (e. g. by testing HTTP status - 304 or etag)
      # engine.should_update(group.name, active_sub_resources)

      ActiveRecord::Base.transaction do
        begin
          recordables = source_hooks_instance.fetch_data(group, sub_resources)
        rescue StandardError => e
          Rails.logger.error "Error during refresh of #{source} instance #{source_instance.id}: #{e.message}"
          next
        end

        recordables.each do |recordable|
          recordable.save
          next unless recordable.record_link.nil?

          source_instance.record_links <<
            RecordLink.create(recordable: recordable, group_id: group)
        end
        source_instance.save

      rescue StandardError => e
        Rails.logger.error e.message
      end
    end
    source_instance.update(last_refresh: job.last_time.to_s)
  rescue => e
    e.inspect
  ensure
    ActiveRecord::Base.connection_pool.release_connection
  end
end
