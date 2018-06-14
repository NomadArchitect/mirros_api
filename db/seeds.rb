# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).

Group.create(
  [
    {
      name: 'calendar'
    },
    {
      name: 'reminder'
    },
    {
      name: 'weather'
    },
    {
      name: 'news'
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

Widget.create(
  [
    {
      name: 'calendar_week',
      title: {'en_GB' => 'Week Calendar', 'de_DE' => 'Wochenkalender'},
      description: {'en_GB' => 'Displays up to five calendars in a week view.', 'de_DE' => 'Zeigt bis zu fünf Kalender in einer Wochenübersicht an.'},
      creator: 'Mattes Angelus',
      version: '1.0.0',
      website: 'https://glancr.de/module/produktivitaet/kalender/',
      download: 'https://api.glancr.de/extensions/widgets/calendar_week-1.0.0.zip',
      groups: [Group.find_by_name('calendar')]
    },
    {
      name: 'calendar_today',
      title: {'en_GB' => 'Calendar Today', 'de_DE' => 'Kalender: Heute'},
      description: {'en_GB' => 'Displays today\'s calendar events.', 'de_DE' => 'Deine Termine für den heutigen Tag.'},
      creator: 'Mattes Angelus',
      version: '1.0.0',
      website: 'https://glancr.de/module/produktivitaet/kalender/',
      download: 'https://api.glancr.de/extensions/widgets/calendar_today-1.0.0.zip',
      groups: [Group.find_by_name('calendar')]
    },
    {
      name: 'todoist',
      title: {'en_GB' => 'Todoist', 'de_DE' => 'Todoist'},
      description: {'en_GB' => 'Shows your tasks from Todoist on your glancr.', 'de_DE' => 'Zeigt deine Aufgaben aus Todoist auf deinem glancr an.'},
      creator: 'Marco Roth',
      version: '1.0.0',
      website: 'https://glancr.de/module/produktivitaet/todos/',
      download: 'https://api.glancr.de/extensions/widgets/todos-1.0.0.zip',
      groups: [Group.find_by_name('reminder')]
    }
  ]
)

Source.create(
  [
    {
      name: 'google',
      creator: 'Mattes Angelus',
      version: '1.0.0',
      website: '',
      download: 'https://api.glancr.de/extensions/sources/google-1.0.0.zip',
      groups: [Group.find_by_name('calendar'), Group.find_by_name('reminder'), Group.find_by_name('news')]
    },
    {
      name: 'icloud',
      creator: 'Mattes Angelus',
      version: '1.0.0',
      website: '',
      download: 'https://api.glancr.de/extensions/sources/icloud-1.0.0.zip',
      groups: [Group.find_by_name('calendar'), Group.find_by_name('reminder')]
    },
    {
      name: 'ical',
      creator: 'Mattes Angelus',
      version: '1.0.0',
      website: '',
      download: 'https://api.glancr.de/extensions/sources/ical-1.0.0.zip',
      groups: [Group.find_by_name('calendar')]
    },
    {
      name: 'wunderlist',
      creator: 'Marco Roth',
      version: '1.0.0',
      website: '',
      download: 'https://api.glancr.de/extensions/sources/wunderlist-1.0.0.zip',
      groups: [Group.find_by_name('reminder')]
    },
    {
      name: 'todoist',
      creator: 'Marco Roth',
      version: '1.0.0',
      website: '',
      download: 'https://api.glancr.de/extensions/sources/todoist-1.0.0.zip',
      groups: [Group.find_by_name('reminder')]
    }
  ]
)

WidgetInstance.create(
  [
    {
      widget: Widget.first,
      position: {
        x: 1,
        y: 1,
        width: 2,
        height: 2
      }
    },
    {
      widget: Widget.last,
      position: {
        x: 10,
        y: 6,
        width: 4,
        height: 2
      }
    }
  ]
)

SourceInstance.create(
  [
    {
      source: Source.find_by_name('ical'),
      configuration: {'url': 'https://calendar.google.com/calendar/ical/de.german%23holiday%40group.v.calendar.google.com/public/basic.ics'}
    }
  ]
)

InstanceAssociation.create(
  [
    {
      configuration: ['calendar'],
      widget_instance: WidgetInstance.first,
      source_instance: SourceInstance.first
    }
  ]
)

Service.create(
  [
    {
      status: 'running',
      parameters: {
        key: 'value'
      },
      # widget: Widget.first
      widget_id: Widget.first
    },
    {
      status: 'stopped',
      parameters: {
        key: 'value'
      },
      # widget: Widget.last
      widget_id: Widget.first
    }
  ]
)
