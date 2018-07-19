class DataRefresher

  # TODO: Clean this up and document methods once we reach a stable API.
  def self.scheduler
    s = Rufus::Scheduler.singleton(:lockfile => "#{Rails.root}/.rufus-scheduler.lock")
    s.stderr = File.open("#{Rails.root}/log/scheduler.log", 'wb')
    return s
  end

  def self.schedule_all
    instances = SourceInstance.all

    instances.each do |sourceInstance|
      schedule(sourceInstance)
    end
  end

  def self.schedule(sourceInstance)
    s = scheduler
    source = sourceInstance.source
    engine = "#{source.name.capitalize}::Hooks".safe_constantize

    if engine.nil?
      Rails.logger.error "Could not instantiate hooks class of engine #{source.name}"
      return
    end

    # Validate the extension's refresh interval.
    begin
      Rufus::Scheduler.parse(engine.refresh_interval)
    rescue ArgumentError => e
      Rails.logger.error "Error parsing refresh rate from #{source.name}: #{e.message}"
      return
    end

    if sourceInstance.configuration.empty?
      Rails.logger.info "Configuration for instance #{sourceInstance.id} of source #{source.name} is empty, aborting."
      return
    end

    job = s.schedule_interval "#{engine.refresh_interval}", :tag => tag_instance(source.name, sourceInstance.id) do |job|
      active_subresources = sourceInstance.instance_associations.pluck('configuration').flatten
      engine_inst = engine.new(sourceInstance.configuration)
      Rails.logger.info "current time: #{Time.now}, refreshing instance #{sourceInstance.id} of #{source.name}"
      sourceInstance.update(last_refresh: job.last_time.to_s, data: engine_inst.fetch_data(active_subresources))
    end
    # Update the job ID once per scheduling, so we have the current one available as a backup.
    sourceInstance.update(job_id: job.job_id)

    Rails.logger.info "scheduled #{tag_instance(source.name, sourceInstance.id)}"
  end

  # Removes the refresh job for a given SourceInstance from the central schedule.
  def self.unschedule(sourceInstance)
    s = scheduler
    tag = tag_instance(sourceInstance.source.name, sourceInstance.id)
    s.jobs(:tag => tag).each(&:unschedule)
    Rails.logger.info "unscheduled job with tag #{tag}"
  end

  def self.tag_instance(source_name, source_instance_id)
    "#{source_name}--#{source_instance_id}"
  end
end
