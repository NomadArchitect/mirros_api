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

  # FIXME: configured_at_boot is a temporary workaround to differentiate between
  # initial setup before first connection attempt and subsequent network problems.
  # Remove once https://gitlab.com/glancr/mirros_api/issues/87 lands
  def self.info
    {
      snap_version: SNAP_VERSION,
      api_version: API_VERSION,
      os: RUBY_PLATFORM,
      rails_env: Rails.env,
      # TODO: Maybe add more settings here as well; define a read_public_settings on SettingsCache
      connection_type: SettingsCache.s[:network_connectiontype]
    }.merge(StateCache.as_json)
  end

  def self.push_status_update
    attempts = 0
    begin
      ActionCable.server.broadcast 'status', payload: info
    rescue StandardError => e
      sleep 2
      retry if (attempts += 1) <= 5

      Rails.logger.error "Failed to push status update: #{e.message} #{e.backtrace_locations}"
    end
  end

  def self.reboot
    # macOS requires sudoers file manipulation without tty/askpass, see
    # https://www.sudo.ws/man/sudoers.man.html
    return if Rails.env.development? # Don't reboot a running dev system
    unless OS.linux?
      raise NotImplementedError, 'Reboot only implemented for Linux hosts'
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
    unless OS.linux?
      raise NotImplementedError, 'Reboot only implemented for Linux hosts'
    end

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

  def self.reload_browser
    cog_s = DBus::ASystemBus.new['com.igalia.Cog']
    cog_o = cog_s['/com/igalia/Cog']
    cog_i = cog_o['org.gtk.Actions']
    # noinspection RubyResolve
    cog_i.Activate('reload', [], {})
  end

  # Restarts the Rails application.
  def self.restart_application
    line = Terrapin::CommandLine.new('bin/rails', 'restart')
    line.run
  end

  def self.current_interface
    conn_type = SettingsCache.s[:network_connectiontype]

    if OS.linux?
      map_interfaces(:linux, conn_type)
    elsif OS.mac?
      map_interfaces(:mac, conn_type)
    else
      raise NotImplementedError 'Not running on a Linux or macOS host'
    end
  end

  def self.determine_linux_distro
    `lsb_release -i -s`
  end

  # TODO: Add support for IPv6.
  # FIXME: Needlessly complex due to OS specifics, split up.
  def self.current_ip_address
    conn_type = SettingsCache.s[:network_connectiontype]
    return nil if conn_type.blank?

    begin
      ip_address = if OS.linux?
                     connection_id = SettingsCache.s.using_wifi? ? SettingsCache.s[:network_ssid] : :glancrlan
                     NmNetwork.find_by(connection_id: connection_id)&.ip4_address
                   elsif OS.mac?
                     # FIXME: This command returns only the IPv4.
                     line = Terrapin::CommandLine.new(
                       'ipconfig',
                       'getifaddr :interface',
                       expected_outcodes: [0, 1]
                     )
                     line.run(interface: map_interfaces(:mac, conn_type))&.chomp!
                   else
                     Rails.logger.error 'Unknown or unsupported OS in query for IP address'
                   end
      ip_address.eql?(SETUP_IP) ? nil : ip_address
    rescue Terrapin::ExitStatusError => e
      Rails.logger.error "Could not determine current IP: #{e.message}"
      nil
    end
  end

  def self.online_state
    if OS.linux?
      NetworkManager::Commands.instance.state
    else
      # TODO: This doesn't reflect intermediate states.
      # if current IP equals SETUP_IP, dnsmasq is active and prevents outgoing connections
      Resolv::DNS.new.getaddress(API_HOST).to_s.eql?(SETUP_IP) ? NmState::DISCONNECTED : NmState::CONNECTED_GLOBAL
    end
  rescue StandardError
    false
  end

  def self.state_is_online?(nm_state)
    nm_state.eql?(NmState::CONNECTED_GLOBAL)
  end

  def self.online?
    online_state.eql?(NmState::CONNECTED_GLOBAL)
  end

  # Determines if the internal access point needs to be opened because mirr.OS does
  # not have an IP address. Also checks if the AP is already open to avoid
  # activating an already-active connection.
  def self.check_network_status
    check_ip_change current_ip_address
    start_offline_mode unless no_offline_mode_required?
  end

  # Tests whether all required parts of the initial setup are present.
  def self.setup_completed?
    network_configured = case SettingsCache.s[:network_connectiontype]
                         when 'wlan'
                           SettingsCache.s[:network_ssid].present? &&
                           SettingsCache.s[:network_password].present?
                         else
                           true
                         end
    email_configured = SettingsCache.s[:personal_email].present?
    network_configured && email_configured
  end

  def self.toggle_timesyncd_ntp(bool)
    return if OS.mac? && Rails.env.development? # Bail in macOS dev env.
    unless OS.linux?
      raise NotImplementedError, 'timedate control only implemented for Linux hosts'
    end
    unless [true, false].include? bool
      raise ArgumentError, "not a valid boolean: #{bool}"
    end # Ruby has no Boolean superclass

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
    unless OS.linux?
      raise NotImplementedError, 'timedate control only implemented for Linux hosts'
    end
    unless epoch_timestamp.class.eql? Integer
      raise ArgumentError, "not an integer: #{epoch_timestamp}"
    end

    timedated_service = DBus::ASystemBus.new['org.freedesktop.timedate1']
    timedated_object = timedated_service['/org/freedesktop/timedate1']
    timedated_interface = timedated_object['org.freedesktop.timedate1']
    # noinspection RubyResolve
    timedated_interface.SetNTP(false, false) # Disable NTP to allow setting the time
    # noinspection RubyResolve
    timedated_interface.SetTime(epoch_timestamp * 1000000, false, false) # timedated requires microseconds
    # noinspection RubyResolve
    timedated_interface.SetNTP(true, false) # Re-enable NTP
  rescue DBus::Error => e
    Rails.logger.error "could not change system time via timesyncd: #{e.message}"
  end

  def self.reset_timezone
    tz = SettingsCache.s[:system_timezone]
    SettingExecution::System.timezone(tz) unless tz.empty?
  rescue StandardError => e
    Rails.logger.error "#{__method__} #{e.message}"
  end

  # @param [Symbol] operating_system
  # @@param [Symbol] interface The interface to query for the current IP.
  def self.map_interfaces(operating_system, interface)
    devices = OS.linux? ? NetworkManager::Commands.instance.list_devices : {}
    {
      mac: { lan: 'en0', wlan: 'en0' },
      linux: {
        lan: devices[:ethernet]&.first&.fetch(:interface),
        wlan: devices[:wifi]&.first&.fetch(:interface)
      }
    }[operating_system][interface.to_sym]
  end

  private_class_method :map_interfaces

  def self.check_ip_change(ip)
    # FIXME: Get macOS support working again.
    return unless OS.linux?
    # Do nothing if we don't have an IP
    return if ip.nil?
    # The IP has not changed in between checks
    return if ip.eql?(NmNetwork.first.ip4_address)
    # Check if the IP has changed after a period of disconnection
    return unless last_known_ip_was_different(ip)

    SettingExecution::Personal.send_change_email
  end

  private_class_method :check_ip_change

  def self.last_known_ip_was_different(ip)
    ip_file = Pathname(Rails.root.join('tmp/last_ip'))
    unless ip_file.readable?
      return false
    end # No dump available, e.g. on first boot

    last_known_ip = File.read(ip_file).chomp
    if last_known_ip.eql?(ip) || ip.nil?
      false
    else
      File.write(ip_file, ip)
      true
    end
  end

  private_class_method :last_known_ip_was_different

  def self.no_offline_mode_required?
    StateCache.online ||
      NmNetwork.exclude_ap.where(active: true).present? ||
      StateCache.nm_state.eql?(NmState::CONNECTING) ||
      SettingExecution::Network.ap_active?
  end

  private_class_method :no_offline_mode_required?

  def self.start_offline_mode
    if setup_completed?
      pause_background_jobs
      start_reconnection_attempts
    else
      SettingExecution::Network.open_ap
    end
  rescue StandardError => e
    Rails.logger.error e.message
  end

  private_class_method :start_offline_mode

  def self.start_reconnection_attempts
    Rufus::Scheduler.s.interval '3m',
                                tag: 'network-reconnect-attempt',
                                overlap: false,
                                times: 3 do |job|
      SettingExecution::Network.connect if SettingsCache.s.using_wifi?
      sleep 5
      if current_ip_address&.present?
        job.unschedule
        resume_background_jobs
      elsif job.count.eql? 3
        SettingExecution::Network.open_ap
        resume_background_jobs
      end
    rescue StandardError => e
      Rails.logger.error e.message
    end
  end

  def self.pause_background_jobs
    Rufus::Scheduler.s.every_jobs(tag: 'network-status-check').each(&:pause)
    Rufus::Scheduler.s.every_jobs(tag: 'network-signal-check').each(&:pause)
  end

  private_class_method :pause_background_jobs

  def self.resume_background_jobs
    Rufus::Scheduler.s.every_jobs(tag: 'network-status-check').each(&:resume)
    Rufus::Scheduler.s.every_jobs(tag: 'network-signal-check').each(&:resume)
  end

  private_class_method :resume_background_jobs
end
