# frozen_string_literal: true

# Generic system-wide scheduling tasks.
class Scheduler
  REBOOT_JOB_TAG = 'system-nightly-reboot'

  # Schedule a nightly reboot at 2am local time.
  # FIXME: Workaround for system hangups, mostly when rotation is active. Revisit when WPE 2.30.2 is working on armhf.
  def self.start_reboot_job
    return if job_running? REBOOT_JOB_TAG

    tz = SettingsCache.s[:system_timezone].present? ? SettingsCache.s[:system_timezone] : 'UTC'
    Rufus::Scheduler.singleton.cron "0 2 * * * #{tz}", tag: REBOOT_JOB_TAG do
      Rails.logger.info "Scheduled reboot from #{REBOOT_JOB_TAG}"
      System.reboot
    end
    Rails.logger.info "scheduled job #{REBOOT_JOB_TAG} every day at 02:00 in #{tz}."\
                      "\t\nnext: #{Rufus::Scheduler.parse_cron("0 2 * * * #{tz}", {})&.next_time&.to_s}"
  end

  # Stop the nightly reboot job.
  def self.stop_reboot_job
    stop_job REBOOT_JOB_TAG
  end

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
