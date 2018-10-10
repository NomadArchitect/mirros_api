#
# config/initializers/scheduler.rb

require 'rufus-scheduler'

# only schedule when not running from the Ruby on Rails console or from a rake task
if Rails.const_defined? 'Server'
  MirrOSApi::DataRefresher.schedule_all

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
