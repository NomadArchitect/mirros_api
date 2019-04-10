namespace :db do
  desc 'Update seeds for mirr.OS system settings'

  # Starting with version 0.4.0, new or changed seeds are added here to allow for seeding a running system.
  task :seed_diff => [:environment] do |task, args|
    Setting.skip_callback :update, :before, :apply_setting
    Setting.skip_callback :update, :after, :update_cache
    Setting.skip_callback :update, :after, :check_setup_status

    # Introduced with 0.5.0 / cbddf259756ce98a659b5f4e7a86187ef0af0511
    tz = Setting.find_or_initialize_by(slug: 'system_timezone')
    if tz.new_record?
      tz.category = 'system'
      tz.key = 'timezone'
      tz.value = ''
      tz.save(validate: false)
    end

    Setting.set_callback :update, :before, :apply_setting
    Setting.set_callback :update, :after, :update_cache
    Setting.set_callback :update, :after, :check_setup_status
  end
end
