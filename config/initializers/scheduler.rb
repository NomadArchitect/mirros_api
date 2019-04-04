#
# config/initializers/scheduler.rb

require 'rufus-scheduler'
require 'yaml'

# only schedule when not running from the Ruby on Rails console or from a rake task
if Rails.const_defined? 'Server'
  # Initialize session
  state_cache = StateCache.singleton

  # FIXME: configured_at_boot is a temporary workaround to differentiate between
  # initial setup before first connection attempt and subsequent network problems.
  # Remove once https://gitlab.com/glancr/mirros_api/issues/87 lands
  state_cache.configured_at_boot = state_cache.setup_complete

  s = Rufus::Scheduler.singleton(lockfile: "#{Rails.root}/tmp/.rufus-scheduler.lock")
  s.stderr = File.open("#{Rails.root}/log/scheduler.log", 'wb')

  MirrOSApi::DataRefresher.schedule_all

  # Perform initial network status check if required and schedule consecutive checking.
  System.check_network_status unless state_cache.current_ip.present?
  Rufus::Scheduler.s.every '30s', tag: 'network-status-check' do
    System.check_network_status
  end
end
