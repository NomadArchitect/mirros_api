# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_07_31_183445) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "calendar_events", primary_key: "uid", id: :string, force: :cascade do |t|
    t.bigint "calendar_id"
    t.datetime "dtstart"
    t.datetime "dtend"
    t.boolean "all_day"
    t.string "summary"
    t.string "description"
    t.index ["calendar_id"], name: "index_calendar_events_on_calendar_id"
  end

  create_table "calendars", force: :cascade do |t|
    t.string "uid"
    t.string "type"
    t.string "name"
    t.string "description"
    t.string "color"
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string "slug", null: false
    t.integer "sluggable_id", null: false
    t.string "sluggable_type", limit: 50
    t.string "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type"
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id"
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type"
  end

  create_table "groups", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "groups_sources", id: false, force: :cascade do |t|
    t.string "group_id"
    t.string "source_id"
    t.index ["group_id"], name: "index_groups_sources_on_group_id"
    t.index ["source_id"], name: "index_groups_sources_on_source_id"
  end

  create_table "groups_widgets", id: false, force: :cascade do |t|
    t.string "group_id"
    t.string "widget_id"
    t.index ["group_id"], name: "index_groups_widgets_on_group_id"
    t.index ["widget_id"], name: "index_groups_widgets_on_widget_id"
  end

  create_table "instance_associations", force: :cascade do |t|
    t.json "configuration"
    t.string "group_id", null: false
    t.bigint "widget_instance_id", null: false
    t.bigint "source_instance_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_instance_associations_on_group_id"
    t.index ["source_instance_id"], name: "index_instance_associations_on_source_instance_id"
    t.index ["widget_instance_id"], name: "index_instance_associations_on_widget_instance_id"
  end

  create_table "record_links", force: :cascade do |t|
    t.string "recordable_type"
    t.bigint "recordable_id"
    t.bigint "source_instance_id"
    t.string "group_id"
    t.index ["group_id"], name: "index_record_links_on_group_id"
    t.index ["recordable_type", "recordable_id"], name: "index_record_links_on_recordable_type_and_recordable_id"
    t.index ["source_instance_id"], name: "index_record_links_on_source_instance_id"
  end

  create_table "reminder_items", primary_key: "uid", id: :string, force: :cascade do |t|
    t.bigint "reminder_list_id"
    t.datetime "dtstart"
    t.string "summary"
    t.string "description"
    t.index ["reminder_list_id"], name: "index_reminder_items_on_reminder_list_id"
  end

  create_table "reminder_lists", force: :cascade do |t|
    t.string "uid"
    t.string "type"
    t.string "name"
    t.string "description"
    t.string "color"
  end

  create_table "services", force: :cascade do |t|
    t.string "status"
    t.json "parameters"
    t.string "widget_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["widget_id"], name: "index_services_on_widget_id"
  end

  create_table "settings", force: :cascade do |t|
    t.string "slug", null: false
    t.string "category", null: false
    t.string "key", null: false
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "source_instances", force: :cascade do |t|
    t.string "source_id"
    t.string "title"
    t.json "configuration"
    t.string "job_id"
    t.datetime "last_refresh"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["source_id"], name: "index_source_instances_on_source_id"
  end

  create_table "sources", force: :cascade do |t|
    t.string "name", null: false
    t.json "title", null: false
    t.json "description", null: false
    t.string "creator"
    t.string "version", null: false
    t.string "website"
    t.string "download", null: false
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_sources_on_slug", unique: true
  end

  create_table "widget_instances", force: :cascade do |t|
    t.string "widget_id"
    t.json "configuration"
    t.json "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["widget_id"], name: "index_widget_instances_on_widget_id"
  end

  create_table "widgets", force: :cascade do |t|
    t.string "name", null: false
    t.json "title", null: false
    t.json "description", null: false
    t.string "version", null: false
    t.string "creator"
    t.string "website"
    t.string "download", null: false
    t.string "slug", null: false
    t.string "icon"
    t.string "languages", default: ["en_GB"], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_widgets_on_slug", unique: true
  end

  add_foreign_key "instance_associations", "source_instances"
  add_foreign_key "instance_associations", "widget_instances"
  add_foreign_key "record_links", "source_instances"
end
