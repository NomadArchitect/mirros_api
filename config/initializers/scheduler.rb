#
# config/initializers/scheduler.rb

require 'rufus-scheduler'
require 'yaml'

# only schedule when not running from the Ruby on Rails console or from a rake task
if Rails.const_defined? 'Server'
  # Initialize session.yml file
  # FIXME: Clean up
  File.write('tmp/session.yml', { refresh_frontend: true }.to_yaml)

  s = Rufus::Scheduler.singleton(lockfile: "#{Rails.root}/tmp/.rufus-scheduler.lock")
  s.stderr = File.open("#{Rails.root}/log/scheduler.log", 'wb')

  MirrOSApi::DataRefresher.schedule_all

  Rails.configuration.connection_attempt = false
  Rails.configuration.setup_complete = System.setup_completed?

  # Store the current IP and schedule consecutive change checks.
  Rails.configuration.current_ip = System.current_ip_address
  Rufus::Scheduler.s.every '1m', tag: 'ip-change-check' do
    System.check_ip_change
  end

  # Perform initial network status check if required and schedule consecutive checking.
  System.check_network_status unless Rails.configuration.current_ip.present?
  Rufus::Scheduler.s.every '2m', tag: 'network-status-check' do
    System.check_network_status
  end
end
