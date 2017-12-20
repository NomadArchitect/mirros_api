# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)


Category.create([
    { name: "productivity" },
    { name: "home-automation" },
    { name: "mobility" },
    { name: "entertainment" },
    { name: "health" }
])

Group.create([
  {
    name: "calendar",
    categories: [ Category.find_by_name("productivity") ]
  },
  {
    name: "todo",
    categories: [ Category.find_by_name("productivity") ]
  },
  {
    name: "weather",
    categories: [ Category.find_by_name("productivity") ]
  },
  {
    name: "news",
    categories: [ Category.find_by_name("productivity") ]
  },
  {
    name: "public-transport",
    categories: [ Category.find_by_name("mobility") ]
  },
  {
    name: "fuel",
    categories: [ Category.find_by_name("mobility") ]
  },
  {
    name: "traffic",
    categories: [ Category.find_by_name("mobility") ]
  },
  {
    name: "music-player",
    categories: [ Category.find_by_name("entertainment") ]
  }
])


Component.create([
  {
    name: "calendar_week",
    author: "Mattes Angelus",
    version: "1.0.0",
    website: "https://glancr.de/module/produktivitaet/kalender/",
    repository: "https://github.com/glancr/calendar_week",
    groups: [ Group.find_by_name("calendar") ],
    categories: [  Category.find_by_name("productivity") ]
  },
  {
    name: "calendar_today",
    author: "Mattes Angelus",
    version: "1.0.0",
    website: "https://glancr.de/module/produktivitaet/kalender/",
    repository: "https://github.com/glancr/calendar_today",
    groups: [ Group.find_by_name("calendar") ],
    categories: [  Category.find_by_name("productivity") ]
  }
])

Source.create([
  {
    name: "google_calendar",
    author: "Mattes Angelus",
    version: "1.0.0",
    website: "",
    repository: "http://github.com/glancr/google_calendar-source",
    groups: [ Group.find_by_name("calendar") ],
    categories: [  Category.find_by_name("productivity") ]
  },
  {
    name: "icloud_calendar",
    author: "Mattes Angelus",
    version: "1.0.0",
    website: "",
    repository: "http://github.com/glancr/icloud_calendar-source",
    groups: [Group.find_by_name("calendar") ],
    categories: [  Category.find_by_name("productivity") ]
  },
  {
    name: "ical_calendar",
    author: "Mattes Angelus",
    version: "1.0.0",
    website: "",
    repository: "http://github.com/glancr/ical_calendar-source",
    groups: [ Group.find_by_name("calendar") ],
    categories: [  Category.find_by_name("productivity") ]
  }
])
