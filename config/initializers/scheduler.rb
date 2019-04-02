#
# config/initializers/scheduler.rb

require 'rufus-scheduler'
require 'yaml'

# Initialize session
state_cache = StateCache.singleton

# FIXME: configured_at_boot is a temporary workaround to differentiate between
# initial setup before first connection attempt and subsequent network problems.
# Remove once https://gitlab.com/glancr/mirros_api/issues/87 lands
state_cache.configured_at_boot = state_cache.setup_complete

# only schedule when not running from the Ruby on Rails console or from a rake task
if Rails.const_defined? 'Server'
  s = Rufus::Scheduler.singleton(lockfile: "#{Rails.root}/tmp/.rufus-scheduler.lock")
  s.stderr = File.open("#{Rails.root}/log/scheduler.log", 'wb')

  MirrOSApi::DataRefresher.schedule_all

  # Store the current IP and schedule consecutive change checks.
  Rufus::Scheduler.s.every '1m', tag: 'ip-change-check' do
    System.check_ip_change
  end

  # Perform initial network status check if required and schedule consecutive checking.
  System.check_network_status unless state_cache.current_ip.present?
  Rufus::Scheduler.s.every '2m', tag: 'network-status-check' do
    System.check_network_status
  end
end
