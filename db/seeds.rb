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
    name: "reminder",
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
  },
  {
    name: "todos",
    author: "Marco Roth",
    version: "1.0.0",
    website: "https://glancr.de/module/produktivitaet/todos/",
    repository: "https://github.com/glancr/todos",
    groups: [ Group.find_by_name("reminder") ],
    categories: [  Category.find_by_name("productivity") ]
  }
])

Source.create([
  {
    name: "google",
    author: "Mattes Angelus",
    version: "1.0.0",
    website: "",
    repository: "http://github.com/glancr/google_source",
    groups: [ Group.find_by_name("calendar"), Group.find_by_name("reminder"), Group.find_by_name("news") ],
    categories: [  Category.find_by_name("productivity") ]
  },
  {
    name: "icloud",
    author: "Mattes Angelus",
    version: "1.0.0",
    website: "",
    repository: "http://github.com/glancr/icloud_source",
    groups: [ Group.find_by_name("calendar"), Group.find_by_name("reminder") ],
    categories: [  Category.find_by_name("productivity") ]
  },
  {
    name: "ical",
    author: "Mattes Angelus",
    version: "1.0.0",
    website: "",
    repository: "http://github.com/glancr/ical_source",
    groups: [ Group.find_by_name("calendar") ],
    categories: [  Category.find_by_name("productivity") ]
  },
  {
    name: "wunderlist",
    author: "Marco Roth",
    version: "1.0.0",
    website: "",
    repository: "http://github.com/glancr/wunderlist_source",
    groups: [ Group.find_by_name("reminder") ],
    categories: [  Category.find_by_name("productivity") ]
  },
  {
    name: "todoist",
    author: "Marco Roth",
    version: "1.0.0",
    website: "",
    repository: "http://github.com/glancr/todoist_source",
    groups: [ Group.find_by_name("reminder") ],
    categories: [  Category.find_by_name("productivity") ]
  }
])


ComponentInstance.create([
  {
    component: Component.first
  },
  {
    component: Component.last
  }
])

SourceInstance.create([
  {
    source: Source.first
  },
  {
    source: Source.last
  }
])
