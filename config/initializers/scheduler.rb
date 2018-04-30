#
# config/initializers/scheduler.rb

require 'rufus-scheduler'

# only schedule when not running from the Ruby on Rails console or from a rake task
unless defined?(Rails::Console) || File.split($PROGRAM_NAME).last == 'rake'
  MirrOSApi::DataRefresher.schedule_all
end
