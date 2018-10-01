# frozen_string_literal: true

require 'os'
require 'resolv'
require 'rake'

# Provides OS-level operations and mirr.OS system information.
class System
  API_HOST = 'api.glancr.de'

  def self.info
    # TODO: complete this
    {
      version: MirrOSApi::Application::VERSION,
      setup_completed: setup_completed?,
      online: online?,
      ip: current_ip,
      os: RUBY_PLATFORM
    }
  end

  def self.reboot
    # TODO: Implement Windows version
    `sudo reboot` if OS.linux? || OS.mac?
  end

  def self.reset
    MirrOSApi::Application.load_tasks
    Rake::Task['db:recycle'].invoke
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

  def self.current_ip
    conn_type = Setting.find_by_slug('network_connectiontype').value
    return '' if conn_type.blank?

    if OS.linux?
      # FIXME: This returns multiple IPs if configured, and ignores connection type
      `hostname --all-ip-addresses`.chomp!
    elsif OS.mac?
      `ipconfig getifaddr #{map_interfaces(:mac, conn_type)}`.chomp!
    elsif OS.windows?
      # TODO: Does Windows have a cmd to JUST show the IP for an interface?
      raise NotImplementedError
    else
      Rails.logger.error 'Could not determine OS in query for IP address'
    end
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

  def self.online?
    Resolv::DNS.new.getaddress(API_HOST)
    true
  rescue Resolv::ResolvError
    false
  end


  # @param [Symbol] operating_system
  # @@param [Symbol] interface The interface to query for the current IP.
  def self.map_interfaces(operating_system, interface)
    {
      'mac': { lan: 'en1', wlan: 'en0' },
      'linux': { lan: 'eth0', wlan: 'wlan0' }
    }[operating_system][interface.to_sym]
  end

  private_class_method :map_interfaces
end
