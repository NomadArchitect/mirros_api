# frozen-string-literal: true

require 'dbus'

module SettingExecution
  # Provides methods to apply settings in the system namespace.
  class System
    # Set the system time zone.
    # @param [String] tz_identifier A valid timezone identifier, see zoneinfo.
    def self.timezone(tz_identifier)
      if OS.linux?
        # FIXME: Use CLI until https://bugs.launchpad.net/snappy/+bug/1650688 is fixed
        # sysbus = DBus.system_bus
        # timedated_service = sysbus['org.freedesktop.timedate1']
        # timedated_object = timedated_service['/org/freedesktop/timedate1']
        # timedated_interface = timedated_object['org.freedesktop.timedate1']
        line = Terrapin::CommandLine.new('timedatectl', 'set-timezone :timezone')
        line.run(timezone: tz_identifier)
        # Ref: https://www.freedesktop.org/wiki/Software/systemd/timedated/
        # tz needs to be a valid timezone from /usr/share/zoneinfo/zone.tab
        # bool: User interaction
        # timedated_interface.SetTimezone(tz_identifier, false)
        #::System.toggle_timesyncd_ntp(true)
        # TODO: See if this needs additional error handling, either here or in controller
      else
        # Bail in macOS dev env or if invoked during rake task
        return if Rails.env.development? || !Rails.const_defined?('Server')

        Rails.logger.warn 'Timezone control only implemented for Linux hosts'
      end
    end

    # Instructs the scheduler to start/stop the rotation job and start/stop rule evaluation.
    # @param [String] state the currently active setting state
    def self.board_rotation(state)
      RuleManager::Scheduler.init_jobs rotation_enabled: state.eql?('on')
    end

    def self.board_rotation_interval(interval)
      RuleManager::Scheduler.start_rotation_interval interval
    end

    # Schedules a system shutdown at a given time of day.
    # @param [String] time_of_day when passed 'hh:mm', will use Rails' String.to_time
    def self.schedule_shutdown(time_of_day)
      return Rails.logger.info "#{__method__}: no-op in development." if Rails.env.development?

      raise NotImplementedError, "#{__method__} only implemented for Linux hosts" unless OS.linux?

      # Uses Rails' String.to_time, will throw ArgumentError if input doesn't contain *any* valid DateTime part.
      # For partially valid strings like "12:aa" it will just omit the minutes.
      parsed = time_of_day.to_time
      # noinspection LongLine
      login_iface = DBus::ASystemBus.new['org.freedesktop.login1']['/org/freedesktop/login1']['org.freedesktop.login1.Manager'] # rubocop:disable Layout/LineLength

      if parsed.blank?
        # noinspection RubyResolve
        login_iface.CancelScheduledShutdown
        ::System.daily_reboot
      else
        # Check if the current time is already past the given time of day,prevents immediate shutdown.
        usec = (parsed.past? ? parsed.next_day(1) : parsed).to_i * 1_000_000 # shutdown expects microseconds
        # noinspection RubyResolve
        login_iface.ScheduleShutdown('poweroff', usec)
      end
    rescue ArgumentError, DBus::Error => e
      Rails.logger.error "[#{__method__}]: #{e.message}"
      raise e
    end

  end
end
