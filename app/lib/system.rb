# frozen_string_literal: true

require 'os'
require 'resolv'

# Provides OS-level operations and mirr.OS system information.
class System
  API_HOST = 'api.glancr.de'

  def self.info
    # TODO: complete this
    ip_address = determine_ip
    {
      version: MirrOSApi::Application::VERSION,
      setup_completed: setup_completed?,
      online: online?,
      ip: ip_address,
      os: RUBY_PLATFORM
    }
  end

  def self.reboot
    # TODO: Implement Windows version
    `sudo reboot` if OS.linux? || OS.mac?
  end

  def self.current_interface
    if OS.linux?
      map_interfaces(:linux)
    elsif OS.mac?
      map_interfaces(:mac)
    else
      Rails.logger.error 'Not running on a Linux or macOS host'
    end
  end

  def self.determine_linux_distro
    `lsb_release -i -s`
  end

  # Tests whether all required parts of the initial setup are present.
  private_class_method def self.setup_completed?
    network_configured = case Setting.find_by_slug('network_connectionType')
                         when 'WLAN'
                           Setting.find('network_ssid').value.present? &&
                           Setting.find('network_ssid').value.present?
                         else
                           true
                         end
    email_configured = Setting.find_by_slug('personal_email').value.present?
    network_configured && email_configured
  end

  private_class_method :setup_completed?

  def self.online?
    Resolv::DNS.new.getaddress(API_HOST)
    true
  rescue Resolv::ResolvError
    false
  end

  private_class_method def self.determine_ip
    if OS.linux?
      # FIXME: This returns multiple IPs if configured, and ignores connection type
      `hostname --all-ip-addresses`.chomp!
    elsif OS.mac?
      `ipconfig getifaddr #{map_interfaces(:mac)}`.chomp!
    elsif OS.windows?
      # FIXME: Does Windows have a cmd to JUST show the IP for an interface?
    else
      Rails.logger.error "Could not determine OS in query for #{conn_type} IP address"
    end
  end

  private_class_method

  # @param [Symbol] operating_system
  def self.map_interfaces(operating_system)
    conn_type = Setting.find('network_connectiontype').value
    {
      'mac': { ETHERNET: 'en0', WLAN: 'en1' },
      'linux': { ETHERNET: 'eth0', WLAN: 'wlan0' }
    }[operating_system][conn_type.to_sym]
  end

end
