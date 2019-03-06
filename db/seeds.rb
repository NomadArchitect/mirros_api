# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).

Setting.create(
  [
=begin
    {
      category: 'display',
      key: 'orientation',
      value: '1'
    },
    {
      category: 'display',
      key: 'offInterval',
      value: 'off'
    },
    {
      category: 'display',
      key: 'offIntervalStart',
      value: ''
    },
    {
      category: 'display',
      key: 'offIntervalEnd',
      value: ''
    },
=end
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
      category: 'system',
      key: 'language',
      value: '' # Settings SPA defaults to browser language until user chooses a language.

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
    }
  ]
)

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
      name: 'fuel'
    },
    {
      name: 'traffic'
    },
    {
      name: 'music_player'
    }
  ]
)

MirrOSApi::Application::DEFAULT_WIDGETS.each do |extension|
  Rake::Task['extension:insert'].reenable
  Rake::Task['extension:insert'].invoke('widget', extension, 'seed')
end

WidgetInstance.create([
                        {
                          widget: Widget.find_by_slug('clock'),
                          title: '',
                          showtitle: false,
                          configuration: {},
                          position: {"x": 0, "y": 0, "width": 3, "height": 1}
                        },
                        {
                          widget: Widget.find_by_slug('current_date'),
                          title: '',
                          showtitle: false,
                          configuration: {},
                          position: {"x": 0, "y": 1, "width": 2, "height": 1}
                        },
                        {
                          widget: Widget.find_by_slug('text_field'),
                          title: '',
                          showtitle: false,
                          configuration: {"alignment": "center", "fontsize": "200", "content": ""},
                          position: {"x": 4, "y": 12, "width": 4, "height": 4}
                        }
                      ])

calendar_widget = WidgetInstance.create(
  widget: Widget.find_by_slug('calendar_event_list'),
  title: 'Feiertage',
  showtitle: true,
  configuration: {},
  position: {"x": 8, "y": 0, "width": 4, "height": 4}
)

MirrOSApi::Application::DEFAULT_SOURCES.each do |extension|
  Rake::Task['extension:insert'].reenable
  Rake::Task['extension:insert'].invoke('source', extension, 'seed')
end

# Skip callbacks to avoid HTTP calls in meta generation
SourceInstance.skip_callback :create, :after, :set_meta
calendar_source = SourceInstance.new(
  source: Source.find_by_slug('ical'),
  title: 'calendar',
  configuration: {"url": 'https://calendar.google.com/calendar/ical/de.german%23holiday%40group.v.calendar.google.com/public/basic.ics'},
  options: [{uid: 'e4ffacba5591440a14a08eac7aade57c603e17c0_0', display: 'calendar'}]
)
calendar_source.save(validate: false)
SourceInstance.set_callback :create, :after, :set_meta

InstanceAssociation.create(
  configuration: {"chosen": ["e4ffacba5591440a14a08eac7aade57c603e17c0_0"]},
  group: Group.find_by_slug('calendar'),
  widget_instance: calendar_widget,
  source_instance: calendar_source

)

newsfeed_widget = WidgetInstance.create(
  widget: Widget.find_by_slug('ticker'),
  title: 'glancr News',
  showtitle: true,
  configuration: {"amount": "5", "showTimestamp": "false", "showFeedIcon": "true"},
  position: {"x": 0, "y": 16, "width": 6, "height": 4}
)

SourceInstance.skip_callback :create, :after, :set_meta
newsfeed_source = SourceInstance.new(
  source: Source.find_by_slug('rss_feeds'),
  title: 'glancr: Welcome Screen',
  configuration: {"feedUrl": "https://glancr.de/mirros-welcome.xml"},
  options: [{uid: 'https://glancr.de/mirros-welcome.xml', display: 'glancr: Welcome Screen'}]
)
newsfeed_source.save(validate: false)
SourceInstance.set_callback :create, :after, :set_meta

InstanceAssociation.create(
  configuration: {"chosen": ["https://glancr.de/mirros-welcome.xml"]},
  group: Group.find_by_slug('newsfeed'),
  widget_instance: newsfeed_widget,
  source_instance: newsfeed_source
)

puts 'Seeding Openweathermap cities table, might take a while ...'
Openweathermap::Engine.load_seed
