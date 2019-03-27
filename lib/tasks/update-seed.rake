namespace :db do
  desc "Update seeds for mirr.OS system settings"

  # Starting with version 0.4.0, new or changed seeds are added here to allow for seeding a running system.
  task :seed_diff => [:environment] do |task, args|
    Setting.skip_callback :update, :apply_setting
    # Introduced with 0.5.0 / cbddf259756ce98a659b5f4e7a86187ef0af0511
    tz = Setting.find_or_initialize_by(slug: 'system_timezone')
    tz.category = 'system'
    tz.key = 'timezone'
    tz.value = ''
    tz.save(validate: false)
    Setting.set_callback :update, :apply_setting
  end
end
