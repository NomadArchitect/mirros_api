# frozen_string_literal: true

require 'os'
require 'resolv'
require 'rake'
require 'yaml'
require 'dbus'

# Provides OS-level operations and mirr.OS system information.
class System
  API_HOST = 'api.glancr.de'
  SETUP_IP = '192.168.8.1' # Fixed IP of the internal setup WiFi AP.

  # TODO: Using stored values in Rails.configuration might have performance potential
  # if the frontend requests system status less frequently than the backend updates itself.
  #
  # FIXME: configured_at_boot is a temporary workaround to differentiate between
  # initial setup before first connection attempt and subsequent network problems.
  # Remove once https://gitlab.com/glancr/mirros_api/issues/87 lands
  def self.info
    info_hash = {
      version: MirrOSApi::Application::VERSION,
      setup_completed: Rails.configuration.setup_complete,
      configured_at_boot: Rails.configuration.configured_at_boot,
      connecting: Rails.configuration.connection_attempt,
      online: online?,
      ip: current_ip_address,
      ap_active: SettingExecution::Network.ap_active?,
      os: RUBY_PLATFORM,
      refresh_frontend: Rails.configuration.refresh_frontend
    }
    Rails.configuration.refresh_frontend = false

    info_hash
  end

  def self.reboot
    # macOS requires sudoers file manipulation without tty/askpass, see
    # https://www.sudo.ws/man/sudoers.man.html
    raise NotImplementedError, 'Reboot only implemented for Linux hosts' unless OS.linux?

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

  # Restarts the Rails application.
  def self.restart_application
    line = Terrapin::CommandLine.new('bin/rails', 'restart')
    line.run
  end

  def self.reset
    # Stop scheduler to prevent running jobs from calling extension methods that are no longer available.
    DataRefresher.scheduler.shutdown(:kill)

    Widget.all.reject {
      |w| MirrOSApi::Application::DEFAULT_WIDGETS.include?(w.id.to_sym)
    }.each(&:uninstall_without_restart)
    Source.all.reject {
      |s| MirrOSApi::Application::DEFAULT_SOURCES.include?(s.id.to_sym)
    }.each(&:uninstall_without_restart)

    # Re-install default widgets/gems if required. bundle add ignores gems that are already present.
    MirrOSApi::Application::DEFAULT_WIDGETS.each do |w|
      line = Terrapin::CommandLine.new('bundle', 'add :gem --source=:source --group=:group --skip-install')
      line.run(gem: w, source: "http://gems.marco-roth.ch", group: 'widget')
    end
    MirrOSApi::Application::DEFAULT_SOURCES.each do |w|
      line = Terrapin::CommandLine.new('bundle', 'add :gem --source=:source --group=:group --skip-install')
      line.run(gem: w, source: "http://gems.marco-roth.ch", group: 'source')
    end
    line = Terrapin::CommandLine.new('bundle', 'install --jobs 5 :exclude')
    line.run(exclude: Rails.env.development? ? nil : '--without=development test')
    line = Terrapin::CommandLine.new('bundle', 'clean')
    line.run
  end

  def self.current_interface
    conn_type = Setting.find_by_slug('network_connectiontype').value

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
  def self.current_ip_address
    conn_type = Setting.find_by_slug('network_connectiontype').value
    return '' if conn_type.blank?

    begin
      if OS.linux?
        # FIXME: When implementing a solution for dynamic interface names, use
        # '-t -m tabular -f GENERAL.TYPE,IP4.ADDRESS d show | grep ":interface" -A 1 | cut -d "/" -f 1'
        # and switch map_interfaces values for Linux to ethernet/wifi generic names.
        line = Terrapin::CommandLine.new('nmcli',
                                         '-t -m tabular -f IP4.ADDRESS \
                                                 d show :interface \
                                                 | cut -d "/" -f 1')
        line.run(interface: map_interfaces(:linux, conn_type))

      elsif OS.mac?
        # FIXME: This command returns only the IPv4.
        line = Terrapin::CommandLine.new(
          'ipconfig', 'getifaddr :interface',
          expected_outcodes: [0, 1]
        )
        line.run(interface: map_interfaces(:mac, conn_type)).chomp!
      else
        Rails.logger.error 'Unknown or unsupported OS in query for IP address'
      end
    rescue Terrapin::ExitStatusError => e
      Rails.logger.error "Could not determine current IP: #{e.message}"
    end
  end

  def self.online?
    return false if Rails.configuration.current_ip.eql? SETUP_IP # dnsmasq is active and prevents outgoing connections

    Resolv::DNS.new.getaddress(API_HOST)
    true
  rescue Resolv::ResolvError, Errno::EHOSTDOWN
    false
  end

  # Check if the IP address has changed and send out a notification if required.
  def self.check_ip_change
    current_ip = current_ip_address
    return if current_ip.eql? Rails.configuration.current_ip

    SettingExecution::Personal.send_change_email if current_ip != SETUP_IP && System.online?
    Rails.configuration.current_ip = current_ip
  end

  # Determines if the internal access point needs to be opened because mirr.OS does
  # not have an IP address. Also checks if the AP is already open to avoid
  # activating an already-active connection.
  def self.check_network_status
    system_has_ip = Rails.configuration.current_ip.present?
    system_is_connecting = Rails.configuration.connection_attempt
    SettingExecution::Network.open_ap unless SettingExecution::Network.ap_active? || system_has_ip || system_is_connecting

  end

  # Tests whether all required parts of the initial setup are present.
  def self.setup_completed?
    network_configured = case Setting.find_by_slug('network_connectiontype').value
                         when 'wlan'
                           Setting.find_by_slug('network_ssid').value.present? &&
                             Setting.find_by_slug('network_password').value.present?
                         else
                           true
                         end
    email_configured = Setting.find_by_slug('personal_email').value.present?
    network_configured && email_configured
  end

  def self.restart_timesyncd
    return if OS.mac? && Rails.env.development? # Bail in macOS dev env.
    raise NotImplementedError, 'timedate control only implemented for Linux hosts' unless OS.linux?

    sysbus = DBus.system_bus
    timedated_service = sysbus['org.freedesktop.timedate1']
    timedated_object = timedated_service['/org/freedesktop/timedate1']
    timedated_interface = timedated_object['org.freedesktop.timedate1']
    timedated_interface.SetNTP(true, false) # Restarts systemd-timesyncd
  rescue DBus::Error => e
    Rails.logger.error "could not toggle NTP via timesyncd: #{e.message}"
  end

  def self.change_system_time(epoch_timestamp)
    return if OS.mac? && Rails.env.development? # Bail in macOS dev env.
    raise NotImplementedError, 'timedate control only implemented for Linux hosts' unless OS.linux?
    raise ArgumentError, "not an integer: #{epoch_timestamp}" unless epoch_timestamp.class.eql? Integer

    sysbus = DBus.system_bus
    timedated_service = sysbus['org.freedesktop.timedate1']
    timedated_object = timedated_service['/org/freedesktop/timedate1']
    timedated_interface = timedated_object['org.freedesktop.timedate1']
    timedated_interface.SetNTP(false, false) # Disable NTP to allow setting the time
    timedated_interface.SetTime(epoch_timestamp, false, false)
    timedated_interface.SetNTP(true, false) # Re-enable NTP
  rescue DBus::Error => e
    Rails.logger.error "could not change system time via timesyncd: #{e.message}"
  end

  # @param [Symbol] operating_system
  # @@param [Symbol] interface The interface to query for the current IP.
  def self.map_interfaces(operating_system, interface)
    # TODO: Maybe use nmcli -f DEVICE,TYPE d | grep -E "(wifi)|(ethernet)" | awk '{ print $1; }' to determine IF names.
    {
      'mac': {lan: 'en0', wlan: 'en0'},
      'linux': {lan: 'eth0', wlan: 'wlan0'}
    }[operating_system][interface.to_sym]
  end

  private_class_method :map_interfaces
end
