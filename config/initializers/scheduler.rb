#
# config/initializers/scheduler.rb

require 'rufus-scheduler'

# only schedule when not running from the Ruby on Rails console or from a rake task
unless defined?(Rails::Console) || File.split($PROGRAM_NAME).last == 'rake'

  s = Rufus::Scheduler.singleton

  instances = SourceInstance.all

  instances.each do |sourceInstance|
    source = sourceInstance.source
    engine = "#{source.name.capitalize}::Engine".safe_constantize
    unless engine.nil?
      begin
        Rufus::Scheduler.parse(engine.schedule_rate)
      rescue ArgumentError => e
        Rails.logger.error "Error parsing schedule rate from #{source.name}: #{e.message}"
        next
      end
      engine_inst = engine.new
      s.every "#{engine.schedule_rate}" do
        Rails.logger.info "#{engine_inst.refresh}, current time: #{Time.now}"
      end
    end
  end
end
