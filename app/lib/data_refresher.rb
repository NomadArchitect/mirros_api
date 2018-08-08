class DataRefresher

  # TODO: Clean this up and document methods once we reach a stable API.
  def self.scheduler
    s = Rufus::Scheduler.singleton(:lockfile => "#{Rails.root}/.rufus-scheduler.lock")
    s.stderr = File.open("#{Rails.root}/log/scheduler.log", 'wb')
    s
  end

  def self.schedule_all
    instances = SourceInstance.all

    instances.each do |source_instance|
      schedule(source_instance)
    end
  end

  def self.schedule(source_instance)
    s = scheduler
    source = source_instance.source

    if source_instance.configuration.empty?
      Rails.logger.info "Configuration for instance #{source_instance.id} of source #{source.name} is empty, aborting."
      return
    end

    source_hooks = "#{source.name.capitalize}::Hooks".safe_constantize
    if source_hooks.nil?
      Rails.logger.error "Could not instantiate hooks class of engine #{source.name}"
      return
    end

    begin
      Rufus::Scheduler.parse(source_hooks.refresh_interval)
    rescue ArgumentError => e
      Rails.logger.error "Error parsing refresh rate from #{source.name}: #{e.message}"
      return
    end

    si_job_tag = tag_instance(source.name, source_instance.id)
    job = s.schedule_interval source_hooks.refresh_interval.to_s, tag: si_job_tag do |job|
      associations = source_instance.instance_associations
      sub_resources = associations.map {|assoc| assoc.configuration.keys}.flatten
      source_hooks_instance = source_hooks.new(source_instance.configuration)

      assocs.pluck('group_id').each do |group|
        # TODO: Specify should_update hook to determine if a SourceInstance needs to be refreshed at all (e. g. by testing HTTP status – 304 means no update necessary)
        # engine.should_update(group.name, active_subresources)
        begin
          source_hooks_instance.fetch_data(group, sub_resources, source_instance.id)
        rescue Error => e
          Rails.logger.error e.message
        end
      end

      # Rails.logger.info "current time: #{Time.now}, refreshing instance #{source_instance.id} of #{source.name}"
      source_instance.update(last_refresh: job.last_time.to_s)
    end
    # Update the job ID once per scheduling, so we have the current one available as a backup.
    source_instance.update(job_id: job.job_id)

    Rails.logger.info "scheduled #{si_job_tag}"
  end

  # Removes the refresh job for a given SourceInstance from the central schedule.
  def self.unschedule(source_instance)
    s = scheduler
    tag = tag_instance(source_instance.source.name, source_instance.id)
    s.jobs(:tag => tag).each(&:unschedule)
    Rails.logger.info "unscheduled job with tag #{tag}"
  end

  def self.tag_instance(source_name, source_instance_id)
    "#{source_name}--#{source_instance_id}"
  end
end
