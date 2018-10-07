#
# config/initializers/scheduler.rb

require 'rufus-scheduler'

# only schedule when not running from the Ruby on Rails console or from a rake task
if Rails.const_defined? 'Server'
  MirrOSApi::DataRefresher.schedule_all

  Rails.configuration.current_ip = System.current_ip
  Rufus::Scheduler.s.every '1m' do
    System.check_ip_change
  end
end
