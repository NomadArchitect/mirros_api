class DataRefresher

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
    engine = "#{source.name.capitalize}::Engine".safe_constantize
    return if engine.nil?

    # Validate the extension's refresh interval.
    begin
      Rufus::Scheduler.parse(engine.refresh_interval)
    rescue ArgumentError => e
      Rails.logger.error "Error parsing refresh rate from #{source.name}: #{e.message}"
      return
    end

    engine_inst = engine.new(sourceInstance.configuration)
    active_subresources = sourceInstance.instance_associations.pluck('configuration').flatten

    s.schedule_interval "#{engine.refresh_interval}" do |job|
      Rails.logger.info "current time: #{Time.now}, refreshing instance #{sourceInstance.id} of #{source.name}"
      #sourceInstance.job_id = job
      #sourceInstance.last_refresh = job.last_time
      puts engine_inst.fetch_data(active_subresources)
      #sourceInstance.data =
      #sourceInstance.save
    end
  end

  # Removes the refresh job for a given SourceInstance from the central schedule.
  def unschedule(sourceInstance)
    s = scheduler
    s.unschedule()
  end
end
