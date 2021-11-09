# frozen_string_literal: true

# Generic system-wide scheduling tasks.
class Scheduler
  # Stops a given Rufus::Scheduler job tag.
  # @param [string] job_tag a Rufus::Scheduler job tag.
  def self.stop_job(job_tag)
    return unless job_running? job_tag

    Rufus::Scheduler.singleton.jobs(tag: job_tag).each(&:unschedule)
    Rails.logger.info "stopped job #{job_tag}"
  end

  # Checks if a job with the given tag is currently running.
  def self.job_running?(tag)
    Rufus::Scheduler.singleton.jobs(tag: tag).present?
  end
end
