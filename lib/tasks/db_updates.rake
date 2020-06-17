# frozen_string_literal: true

namespace :db do
  # Starting with version 0.4.0, new or changed seeds are added here to allow for seeding a running system.
  desc 'Update seeds for mirr.OS system settings'
  task seed_diff: [:environment] do |_task, _args|
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

    Setting.find_or_create_by(slug: 'system_backgroundimage') do |entry|
      entry.category = 'system'
      entry.key = 'backgroundImage'
      entry.value = ''
    end

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
      entry.value = 'no'
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
  end

  desc 'Sync all default extension\'s gem specs to the database'
  task update_default_gems: [:environment] do |_task, _args|
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
