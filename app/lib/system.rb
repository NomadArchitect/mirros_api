# frozen_string_literal: true

require 'os'
require 'resolv'
require 'rake'
require 'yaml'
require 'dbus'

# Provides OS-level operations and mirr.OS system information.
class System
  include NetworkManager::Constants
  API_HOST = 'api.glancr.de'
  SETUP_IP = '192.168.8.1' # Fixed IP of the internal setup WiFi AP.

  def self.running_in_snap?
    ENV['SNAP'].present?
  end

  # FIXME: configured_at_boot is a temporary workaround to differentiate between
  # initial setup before first connection attempt and subsequent network problems.
  # Remove once https://gitlab.com/glancr/mirros_api/issues/87 lands
  def self.status
    state = {}
    SystemState.pluck(:variable, :value).each do |variable, value|
      state[variable] = value
    end

    {
      snap_version: SNAP_VERSION,
      api_version: API_VERSION,
      os: RUBY_PLATFORM,
      rails_env: Rails.env,
    }.merge(
      StateCache.as_json,
      state,
      network: NetworkManager::Bus.new.state_hash
      )
  end

  def self.push_status_update
    attempts = 0
    begin
      ActionCable.server.broadcast 'status', payload: status
    rescue StandardError => e
      sleep 2
      retry if (attempts += 1) <= 5

      Rails.logger.error "Failed to push status update: #{e.message} #{e.backtrace_locations}"
    end
  end

  # @return [TrueClass, FalseClass] Returns true if selected connection type is WiFi, false otherwise.
  def self.using_wifi?
    Setting.value_for(:network_connectiontype).eql? 'wlan'
  end

  # @return [TrueClass, FalseClass] True if board rotation is currently enabled, false otherwise.
  def self.board_rotation_enabled?
    Setting.value_for(:system_boardrotation).eql? 'on'
  end

  def self.online?
    NetworkManager::Bus.new.connected?
  end

  def self.reboot
    # macOS requires sudoers file manipulation without tty/askpass, see
    # https://www.sudo.ws/man/sudoers.man.html
    unless OS.linux?
      raise NotImplementedError, 'Reboot only implemented for Linux hosts' if Rails.env.production?

      Rails.logger.warn "#{__method__} not implemented for #{OS.config['host_os']}"
      return
    end

    # TODO: Refactor with ruby-dbus for consistency
    line = Terrapin::CommandLine.new(
      'dbus-send',
      '--system \
      --print-reply \
      --dest=org.freedesktop.login1 \
      /org/freedesktop/login1 \
      "org.freedesktop.login1.Manager.Reboot" \
      boolean:true'
    )
    line.run
  rescue Terrapin::ExitStatusError => e
    Rails.logger.error "Error during reboot attempt: #{e.message}"
    raise e
  end

  def self.shut_down
    # macOS requires sudoers file manipulation without tty/askpass, see
    # https://www.sudo.ws/man/sudoers.man.html
    return if Rails.env.development? # Don't reboot a running dev system
    raise NotImplementedError, 'Reboot only implemented for Linux hosts' unless OS.linux?

    # TODO: Refactor with ruby-dbus for consistency
    line = Terrapin::CommandLine.new(
      'dbus-send',
      '--system \
      --print-reply \
      --dest=org.freedesktop.login1 \
      /org/freedesktop/login1 \
      "org.freedesktop.login1.Manager.PowerOff" \
      boolean:true'
    )
    line.run
  rescue Terrapin::ExitStatusError => e
    Rails.logger.error "Error during shutdown attempt: #{e.message}"
    raise e
  end

  # Quits a running cog instance, will be restarted by systemd.
  def self.reload_browser
    return unless running_in_snap?

    cog_s = DBus::ASystemBus.new['com.igalia.Cog']
    cog_o = cog_s['/com/igalia/Cog']
    cog_i = cog_o['org.gtk.Actions']
    # noinspection RubyResolve
    cog_i.Activate('quit', [], {})
  end

  # Restarts the Rails application.
  def self.restart_application
    line = Terrapin::CommandLine.new('bin/rails', 'restart')
    line.run
  end

  # Tests whether all required parts of the initial setup are present.
  def self.setup_completed?
    network_configured = case Setting.value_for :network_connectiontype
                         when 'wlan'
                           Setting.value_for(:network_ssid).present? &&
                             Setting.value_for(:network_password).present?
                         else
                           true
                         end
    email_configured = Setting.value_for(:personal_email).present?
    network_configured && email_configured
  end

  def self.toggle_timesyncd_ntp(bool)
    return if OS.mac? && Rails.env.development? # Bail in macOS dev env.
    raise NotImplementedError, 'timedate control only implemented for Linux hosts' unless OS.linux?
    # Ruby has no Boolean superclass
    unless [true, false].include? bool
      raise ArgumentError, "not a valid boolean: #{bool}"
    end

    timedated_service = DBus::ASystemBus.new['org.freedesktop.timedate1']
    timedated_object = timedated_service['/org/freedesktop/timedate1']
    timedated_interface = timedated_object['org.freedesktop.timedate1']
    # noinspection RubyResolve
    timedated_interface.SetNTP(bool, false) # Restarts systemd-timesyncd
  rescue DBus::Error => e
    Rails.logger.error "could not toggle NTP via timesyncd: #{e.message}"
  end

  # @param [Integer] epoch_timestamp A valid Unix timestamp in seconds.
  # @return [Array] Return messages from DBus call, if any
  def self.change_system_time(epoch_timestamp)
    return if OS.mac? && Rails.env.development? # Bail in macOS dev env.
    raise NotImplementedError, 'timedate control only implemented for Linux hosts' unless OS.linux?
    unless epoch_timestamp.instance_of?(Integer)
      raise ArgumentError, "not an integer: #{epoch_timestamp}"
    end

    timedated_service = DBus::ASystemBus.new['org.freedesktop.timedate1']
    timedated_object = timedated_service['/org/freedesktop/timedate1']
    timedated_interface = timedated_object['org.freedesktop.timedate1']
    # noinspection RubyResolve
    timedated_interface.SetNTP(false, false) # Disable NTP to allow setting the time
    # noinspection RubyResolve
    timedated_interface.SetTime(epoch_timestamp * 1_000_000, false, false) # timedated requires microseconds
    # noinspection RubyResolve
    timedated_interface.SetNTP(true, false) # Re-enable NTP
  rescue DBus::Error => e
    Rails.logger.error "could not change system time via timesyncd: #{e.message}"
  end

  def self.reset_timezone
    tz = Setting.value_for(:system_timezone)
    SettingExecution::System.timezone(tz) unless tz.nil?
  rescue StandardError => e
    Rails.logger.error "#{__method__} #{e.message}"
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
