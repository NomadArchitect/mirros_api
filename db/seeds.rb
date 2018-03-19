# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

Category.create(
  [
    { name: "productivity" },
    { name: "home-automation" },
    { name: "mobility" },
    { name: "entertainment" },
    { name: "health" }
  ]
)

Group.create(
  [
    {
      name: "calendar",
      categories: [Category.find_by_name("productivity")]
    },
    {
      name: "reminder",
      categories: [Category.find_by_name("productivity")]
    },
    {
      name: "weather",
      categories: [Category.find_by_name("productivity")]
    },
    {
      name: "news",
      categories: [Category.find_by_name("productivity")]
    },
    {
      name: "public-transport",
      categories: [Category.find_by_name("mobility")]
    },
    {
      name: "fuel",
      categories: [Category.find_by_name("mobility")]
    },
    {
      name: "traffic",
      categories: [Category.find_by_name("mobility")]
    },
    {
      name: "music-player",
      categories: [Category.find_by_name("entertainment")]
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
      categories: [Category.find_by_name("productivity")],
      installed: true
    },
    {
      name: "calendar_today",
      creator: "Mattes Angelus",
      version: "1.0.0",
      website: "https://glancr.de/module/produktivitaet/kalender/",
      groups: [Group.find_by_name("calendar")],
      categories: [Category.find_by_name("productivity")],
      installed: false
    },
    {
      name: "todos",
      creator: "Marco Roth",
      version: "1.0.0",
      website: "https://glancr.de/module/produktivitaet/todos/",
      groups: [Group.find_by_name("reminder")],
      categories: [Category.find_by_name("productivity")],
      installed: true
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
      categories: [Category.find_by_name("productivity")],
      installed: true
    },
    {
      name: "icloud",
      creator: "Mattes Angelus",
      version: "1.0.0",
      website: "",
      groups: [Group.find_by_name("calendar"), Group.find_by_name("reminder")],
      categories: [ Category.find_by_name("productivity")],
      installed: true
    },
    {
      name: "ical",
      creator: "Mattes Angelus",
      version: "1.0.0",
      website: "",
      groups: [Group.find_by_name("calendar")],
      categories: [Category.find_by_name("productivity")],
      installed: false
    },
    {
      name: "wunderlist",
      creator: "Marco Roth",
      version: "1.0.0",
      website: "",
      groups: [Group.find_by_name("reminder")],
      categories: [Category.find_by_name("productivity")],
      installed: true
    },
    {
      name: "todoist",
      creator: "Marco Roth",
      version: "1.0.0",
      website: "",
      groups: [Group.find_by_name("reminder")],
      categories: [Category.find_by_name("productivity")],
      installed: true
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
