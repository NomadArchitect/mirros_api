# frozen_string_literal: true

require 'os'
require 'resolv'
require 'rake'

# Provides OS-level operations and mirr.OS system information.
class System
  API_HOST = 'api.glancr.de'

  # TODO: Using stored values in Rails.configuration might have performance potential
  # if the frontend requests system status less frequently than the backend updates itself.
  def self.info
    {
      version: MirrOSApi::Application::VERSION,
      setup_completed: setup_completed?,
      online: online?,
      ip: current_ip_address,
      ap_active: SettingExecution::Network.ap_active?,
      os: RUBY_PLATFORM
    }
  end

  def self.reboot
    `sudo reboot` if OS.linux? || OS.mac?
  end

  # Restarts the Rails application.
  def self.restart_application
    line = Terrapin::CommandLine.new('bin/rails', 'restart')
    line.run
  end

  def self.reset
    Source.all.each(&:uninstall_without_restart)
    SettingExecution::Personal.send_reset_email

    MirrOSApi::Application.load_tasks
    Rake::Task['db:recycle'].invoke
    SettingExecution::Network.reset unless Setting.find_by_slug('network_connectiontype').value == 'lan'

    restart_application
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
      line = Terrapin::CommandLine.new('ipconfig', 'getifaddr :interface')
      line.run(interface: map_interfaces(:mac, conn_type)).chomp!
    else
      Rails.logger.error 'Unknown or unsupported OS in query for IP address'
    end
  end

  def self.online?
    return false if SettingExecution::Network.ap_active? # dnsmasq is active and prevents outgoing connections

    Resolv::DNS.new.getaddress(API_HOST)
    true
  rescue Resolv::ResolvError, Errno::EHOSTDOWN
    false
  end

  # Sends out a notification if the IP address of the configured interface has
  # changed, is not empty (i. e. we have no IP) and the system has connectivity.
  def self.check_ip_change
    current_ip = current_ip_address
    if Rails.configuration.current_ip != current_ip
      # Do not attempt to send an email if the current IP is empty or we are offline
      SettingExecution::Personal.send_change_email if current_ip.present? && System.online?
      Rails.configuration.current_ip = current_ip
    end
  end

  # Determines if the internal access point needs to be opened because mirr.OS does
  # not have an IP address. Also checks if the AP is already open to avoid
  # activating an already-active connection.
  def self.check_network_status
    system_has_ip = Rails.configuration.current_ip.present?
    SettingExecution::Network.open_ap unless system_has_ip || SettingExecution::Network.ap_active?
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

  private_class_method :setup_completed?


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
