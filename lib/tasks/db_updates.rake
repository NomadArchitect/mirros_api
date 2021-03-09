# frozen_string_literal: true

namespace :db do
  # Starting with version 0.4.0, new or changed seeds are added here to allow for seeding a running system.
  desc 'Update seeds for mirr.OS system settings'
  task seed_diff: [:environment] do |_task, _args|
    # FIXME: Replace with cleaner variant e.g. like in seeds.rb

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

    Setting.find_or_create_by(slug: 'system_backgroundcolor') do |entry|
      entry.category = 'system'
      entry.key = 'backgroundColor'
      entry.value = '#000000'
    end

    Setting.find_or_create_by(slug: 'system_fontcolor') do |entry|
      entry.category = 'system'
      entry.key = 'fontColor'
      entry.value = '#ffffff'
    end

    bg_setting = Setting.find_by(slug: 'system_backgroundimage')
    Upload.find_by(id: bg_setting.value.to_i)&.destroy if bg_setting&.value.present?
    bg_setting&.destroy

    Setting.find_or_create_by(slug: 'personal_productkey') do |entry|
      entry.category = 'personal'
      entry.key = 'productKey'
      entry.value = ''
    end

    Setting.find_or_create_by(slug: 'system_themecolor') do |entry|
      entry.category = 'system'
      entry.key = 'themeColor'
      entry.value = '#8ba4c1'
    end

    Setting.find_or_create_by(slug: 'system_headerlogo') do |entry|
      entry.category = 'system'
      entry.key = 'headerLogo'
      entry.value = ''
    end

    # BEGIN boards feature
    default_board = Board.find_or_create_by(id: 1) do |board|
      board.title = 'default'
    end

    Setting.find_or_create_by(slug: 'system_multipleboards') do |entry|
      entry.category = 'system'
      entry.key = 'multipleBoards'
      entry.value = 'off'
    end

    Setting.find_or_create_by(slug: 'system_activeboard') do |entry|
      entry.category = 'system'
      entry.key = 'activeBoard'
      entry.value = default_board.id.to_s
    end

    setting = Setting.find_or_initialize_by(slug: 'system_showerrornotifications') do |entry|
      entry.category = 'system'
      entry.key = 'showErrorNotifications'
      entry.value = 'on'
    end
    setting.save(validate: false) if setting.new_record?

    WidgetInstance.all.select { |w| w.board.eql? nil }.each do |wi|
      wi.update board: default_board
    end
    # END boards feature

    Group.find_or_create_by(name: 'current_weather') do |group|
      group.name = 'current_weather'
    end

    setting_rotation = Setting.find_or_initialize_by(slug: 'system_boardrotation') do |entry|
      entry.category = 'system'
      entry.key = 'boardRotation'
      entry.value = 'off'
    end
    setting_rotation.save(validate: false) if setting_rotation.new_record?

    setting_rotation_interval = Setting.find_or_initialize_by(slug: 'system_boardrotationinterval') do |entry|
      entry.category = 'system'
      entry.key = 'boardRotationInterval'
      entry.value = '1m'
    end
    setting_rotation_interval.save(validate: false) if setting_rotation_interval.new_record?

    setting_display_font = Setting.find_or_initialize_by(slug: 'system_displayfont') do |entry|
      entry.category = 'system'
      entry.key = 'displayFont'
      entry.value = 'alegreya'
    end
    setting_display_font.save(validate: false) if setting_display_font.new_record?

    setting_password_protection = Setting.find_or_initialize_by(slug: 'system_passwordprotection') do |entry|
      entry.category = 'system'
      entry.key = 'passwordProtection'
      entry.value = 'off'
    end
    setting_password_protection.save(validate: false) if setting_password_protection.new_record?

    setting_password = Setting.find_or_initialize_by(slug: 'system_adminpassword') do |entry|
      entry.category = 'system'
      entry.key = 'adminPassword'
      entry.value = ''
    end
    setting_password.save(validate: false) if setting_password.new_record?

    setting_schedule_shutdown = Setting.find_or_initialize_by(slug: 'system_scheduleshutdown') do |entry|
      entry.category = 'system'
      entry.key = 'scheduleShutdown'
      entry.value = ''
    end
    setting_schedule_shutdown.save(validate: false) if setting_schedule_shutdown.new_record?
  end

  desc 'Sync all default extension\'s gem specs to the database. Deletes removed extensions from the DB, unless they were manually installed.'
  task update_default_gems: [:environment] do |_task, _args|
    manually_installed = Bundler.load
                                .current_dependencies
                                .select { |dep| dep.groups.include?(:manual) }.map(&:name).freeze

    Widget.pluck('name').difference(MirrOSApi::Application::DEFAULT_WIDGETS, manually_installed).each do |widget_name|
      next if MirrOSApi::Application::DEFAULT_WIDGETS.include?("mirros-widget-#{widget_name}")
      Widget.find_by(name: widget_name)&.destroy
      puts "Removed #{widget_name} as it is no longer listed as a default or manually installed widget."
    end

    MirrOSApi::Application::DEFAULT_WIDGETS.each do |widget|
      Rake::Task['extension:update'].reenable
      Rake::Task['extension:update'].invoke(widget)
    rescue StandardError => e
      puts "#{e.message}, trying insert task"
      begin
        Rake::Task['extension:insert'].reenable
        Rake::Task['extension:insert'].invoke(widget)
      rescue StandardError => e
        puts e.message
        next
      end
    end

    Source.pluck('name').difference(MirrOSApi::Application::DEFAULT_SOURCES, manually_installed).each do |source_name|
      next if MirrOSApi::Application::DEFAULT_SOURCES.include?("mirros-source-#{source_name}")
      Source.find_by(name: source_name)&.destroy
      puts "Removed #{source_name} as it is no longer listed as a default or manually installed source."
    end

    MirrOSApi::Application::DEFAULT_SOURCES.each do |source|
      Rake::Task['extension:update'].reenable
      Rake::Task['extension:update'].invoke(source)
    rescue StandardError => e
      puts "#{e.message}, trying insert task"
      begin
        Rake::Task['extension:insert'].reenable
        Rake::Task['extension:insert'].invoke(source)
      rescue StandardError => e
        puts e.message
        next
      end
    end
  end
end
