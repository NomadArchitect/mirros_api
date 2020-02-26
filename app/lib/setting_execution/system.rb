# frozen-string-literal: true

require 'dbus'

module SettingExecution
  # Provides methods to apply settings in the system namespace.
  class System
    def self.timezone(tz_identifier)
      if OS.mac?
        # Bail in macOS dev env or if invoked during rake task
        return if Rails.env.development? || !Rails.const_defined?('Server')

        raise NotImplementedError, 'Timezone control only implemented for Linux hosts'
      end

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
    end
  end
end
