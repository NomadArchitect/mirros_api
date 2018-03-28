# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)


Group.create(
  [
    {
      name: "calendar",
    },
    {
      name: "reminder",
    },
    {
      name: "weather",
    },
    {
      name: "news",
    },
    {
      name: "public-transport",
    },
    {
      name: "fuel",
    },
    {
      name: "traffic",
    },
    {
      name: "music-player",
    }
  ]
)


Widget.create(
  [
    {
      name: "calendar_week",
      creator: "Mattes Angelus",
      version: "1.0.0",
      website: "https://glancr.de/module/produktivitaet/kalender/",
      groups: [Group.find_by_name("calendar")],
    },
    {
      name: "calendar_today",
      creator: "Mattes Angelus",
      version: "1.0.0",
      website: "https://glancr.de/module/produktivitaet/kalender/",
      groups: [Group.find_by_name("calendar")],
    },
    {
      name: "todos",
      creator: "Marco Roth",
      version: "1.0.0",
      website: "https://glancr.de/module/produktivitaet/todos/",
      groups: [Group.find_by_name("reminder")],
    }
  ]
)

Source.create(
  [
    {
      name: "google",
      creator: "Mattes Angelus",
      version: "1.0.0",
      website: "",
      groups: [Group.find_by_name("calendar"), Group.find_by_name("reminder"), Group.find_by_name("news")],
    },
    {
      name: "icloud",
      creator: "Mattes Angelus",
      version: "1.0.0",
      website: "",
      groups: [Group.find_by_name("calendar"), Group.find_by_name("reminder")],
    },
    {
      name: "ical",
      creator: "Mattes Angelus",
      version: "1.0.0",
      website: "",
      groups: [Group.find_by_name("calendar")],
    },
    {
      name: "wunderlist",
      creator: "Marco Roth",
      version: "1.0.0",
      website: "",
      groups: [Group.find_by_name("reminder")],
    },
    {
      name: "todoist",
      creator: "Marco Roth",
      version: "1.0.0",
      website: "",
      groups: [Group.find_by_name("reminder")],
    }
  ]
)


WidgetInstance.create(
  [
    {
      widget: Widget.first
    },
    {
      widget: Widget.last
    }
  ]
)

SourceInstance.create(
  [
    {
      source: Source.first
    },
    {
      source: Source.last
    }
  ]
)


Service.create(
  [
    {
      status: "running",
      parameters: {
        key: "value"
      },
      # widget: Widget.first
      widget_id: Widget.first
    },
    {
      status: "stopped",
      parameters: {
        key: "value"
      },
      # widget: Widget.last
      widget_id: Widget.first
    },
  ]
)
