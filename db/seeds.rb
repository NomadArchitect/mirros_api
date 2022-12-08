# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
default_board = Board.create(title: 'default')

settings = [
  {
    category: 'network',
    key: 'connectionType',
    value: 'wlan'
  },
  {
    category: 'network',
    key: 'ssid',
    value: ''
  },
  {
    category: 'network',
    key: 'ssidInvisible',
    value: 'no' # Requires frontend to specify checkbox values.
  },
  {
    category: 'network',
    key: 'password',
    value: ''
  },
  {
    category: 'network',
    key: 'localMode',
    value: 'off'
  },
  {
    category: 'personal',
    key: 'email',
    value: ''
  },
  {
    category: 'personal',
    key: 'name',
    value: ''
  },
  {
    category: 'personal',
    key: 'privacyConsent',
    value: 'no' # Requires frontend to specify checkbox values.
  },
  {
    category: 'system',
    key: 'backgroundColor',
    value: '#000000'
  },
  {
    category: 'system',
    key: 'fontColor',
    value: '#ffffff'
  },
  {
    category: 'system',
    key: 'backgroundImage',
    value: ''
  },
  {
    category: 'system',
    key: 'themeColor',
    value: '#8ba4c1'
  },
  {
    category: 'system',
    key: 'headerLogo',
    value: ''
  },
  {
    category: 'system',
    key: 'multipleBoards',
    value: 'off'
  },
  {
    category: 'system',
    key: 'activeBoard',
    value: default_board.id.to_s
  },
  {
    category: 'system',
    key: 'language',
    value: ''
  },
  {
    category: 'system',
    key: 'timezone',
    value: ''
  },
  {
    category: 'system',
    key: 'showErrorNotifications',
    value: 'on'
  },
  {
    category: 'system',
    key: 'boardRotation',
    value: 'off'
  },
  {
    category: 'system',
    key: 'boardRotationInterval',
    value: '1m'
  },
  {
    category: 'system',
    key: 'displayFont',
    value: 'alegreya'
  },
  {
    category: 'system',
    'key': 'passwordProtection',
    value: ''
  },
  {
    category: 'system',
    'key': 'adminPassword',
    value: ''
  },
  {
    category: 'system',
    'key': 'scheduleShutdown',
    value: ''
  }
]
# Bypasses validation since some settings would raise errors or trigger system calls.
settings.each do |setting|
  setting = Setting.new(setting)
  setting.slug = setting.category_and_key.downcase
  setting.save(validate: false)
end

Group.create(
  [
    {
      name: 'calendar'
    },
    {
      name: 'reminder_list'
    },
    {
      name: 'weather_owm'
    },
    {
      name: 'newsfeed'
    },
    {
      name: 'public_transport'
    },
    {
      name: 'idiom_collection'
    },
    {
      name: 'current_weather'
    }
  ]
)

SystemState.create(variable: :welcome_mail_sent, value: false)

MirrOSApi::Application::DEFAULT_WIDGETS.each do |extension|
  Rake::Task['extension:insert'].reenable
  Rake::Task['extension:insert'].invoke(extension)

  has_seed = Widget.find_by(slug: extension)&.engine_class&.load_seed
  puts "Successfully ran #{extension} seed" if has_seed
end

MirrOSApi::Application::DEFAULT_SOURCES.each do |extension|
  Rake::Task['extension:insert'].reenable
  Rake::Task['extension:insert'].invoke(extension)

  has_seed = Source.find_by(slug: extension)&.engine_class&.load_seed
  puts "Successfully ran #{extension} seed" if has_seed
end
