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

  def self.daily_reboot
    return Rails.logger.info "#{__method__}: no-op in development." if Rails.env.development?

    raise NotImplementedError, "#{__method__} only implemented for Linux hosts" unless OS.linux?

    next_day_2am = Time.current.at_midnight.advance(days: 1, hours: 2)
    # noinspection LongLine
    login_iface = DBus::ASystemBus.new['org.freedesktop.login1']['/org/freedesktop/login1']['org.freedesktop.login1.Manager'] # rubocop:disable Layout/LineLength
    # noinspection RubyResolve
    login_iface.ScheduleShutdown('reboot', next_day_2am.to_i * 1_000_000)
    Rails.logger.info "Scheduled reboot at #{next_day_2am}"
  rescue DBus::Error => e
    Rails.logger.error "[#{__method__}]: #{e.message}"
    raise e
  end
end
