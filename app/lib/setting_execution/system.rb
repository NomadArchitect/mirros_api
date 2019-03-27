# frozen-string-literal: true

require 'dbus'

module SettingExecution

  # Provides methods to apply settings in the system namespace.
  class System
    def self.timezone(tz_identifier)
      return if OS.mac? && Rails.env.development? # Bail in macOS dev env.
      raise NotImplementedError, 'Timezone control only implemented for Linux hosts' unless OS.linux?

      sysbus = DBus.system_bus
      timedated_service = sysbus['org.freedesktop.timedate1']
      timedated_object = timedated_service['/org/freedesktop/timedate1']
      timedated_interface = timedated_object['org.freedesktop.timedate1']
      # Ref: https://www.freedesktop.org/wiki/Software/systemd/timedated/
      # tz needs to be a valid timezone from /usr/share/zoneinfo/zone.tab
      # bool: User interaction
      timedated_interface.SetTimezone(tz_identifier, false)
      ::System.toggle_timesyncd_ntp(true)
      # TODO: See if this needs additional error handling, either here or in controller
    end
  end


end
