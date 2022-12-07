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

ActiveRecord::Schema.define(version: 2022_12_02_114731) do

  create_table "active_storage_attachments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "boards", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "uploads_id"
    t.index ["uploads_id"], name: "index_boards_on_uploads_id"
  end

  create_table "friendly_id_slugs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
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

  create_table "group_schemas_calendar_events", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "uid", null: false
    t.string "calendar_id"
    t.datetime "dtstart"
    t.datetime "dtend"
    t.boolean "all_day"
    t.string "summary"
    t.text "description"
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "several_days", default: false
    t.index ["calendar_id"], name: "index_group_schemas_calendar_events_on_calendar_id"
  end

  create_table "group_schemas_calendars", id: :string, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "type"
    t.string "name"
    t.string "description"
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "group_schemas_current_weather_entries", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "uid", null: false
    t.float "temperature"
    t.integer "humidity"
    t.float "wind_speed"
    t.integer "wind_angle"
    t.float "air_pressure"
    t.integer "rain_last_hour"
    t.string "condition_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "current_weather_id"
    t.string "unit"
    t.decimal "pop", precision: 3, scale: 2
    t.index ["current_weather_id"], name: "items_on_current_weather_id"
  end

  create_table "group_schemas_current_weathers", id: :string, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "type"
    t.string "station_name"
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "group_schemas_idiom_collection_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "uid", null: false
    t.string "idiom_collection_id"
    t.string "title"
    t.text "message"
    t.text "author"
    t.string "language"
    t.date "date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["idiom_collection_id"], name: "items_on_idiom_collection_id"
  end

  create_table "group_schemas_idiom_collections", id: :string, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "type"
    t.string "collection_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "group_schemas_newsfeed_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "uid", null: false
    t.string "newsfeed_id"
    t.string "title"
    t.text "content"
    t.string "url", limit: 700
    t.datetime "published"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["newsfeed_id"], name: "index_group_schemas_newsfeed_items_on_newsfeed_id"
  end

  create_table "group_schemas_newsfeeds", id: :string, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "type"
    t.string "name"
    t.string "url", null: false
    t.string "icon_url"
    t.datetime "latest_entry"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["url"], name: "index_group_schemas_newsfeeds_on_url"
  end

  create_table "group_schemas_public_transport_departures", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "uid", null: false
    t.string "public_transport_id"
    t.datetime "departure", null: false
    t.integer "delay_minutes"
    t.string "line", null: false
    t.string "direction", null: false
    t.string "transit_type"
    t.string "platform"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["public_transport_id"], name: "departures_on_public_transport_id"
  end

  create_table "group_schemas_public_transports", id: :string, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "type"
    t.string "station_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "group_schemas_reminder_items", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "uid", null: false
    t.string "reminder_list_id"
    t.datetime "due_date"
    t.datetime "creation_date"
    t.boolean "completed"
    t.string "summary"
    t.text "description"
    t.string "assignee"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reminder_list_id"], name: "index_group_schemas_reminder_items_on_reminder_list_id"
  end

  create_table "group_schemas_reminder_lists", id: :string, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "type"
    t.string "name"
    t.string "description"
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["id"], name: "index_group_schemas_reminder_lists_on_id"
  end

  create_table "group_schemas_weather_owm_entries", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "weather_owm_id"
    t.datetime "dt_txt", null: false
    t.json "forecast"
    t.string "unit"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["weather_owm_id"], name: "index_group_schemas_weather_owm_entries_on_weather_owm_id"
  end

  create_table "group_schemas_weather_owms", id: :string, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "type"
    t.string "location_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "sunrise"
    t.datetime "sunset"
  end

  create_table "groups", primary_key: "name", id: :string, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "groups_sources", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "group_id"
    t.string "source_id"
    t.index ["group_id"], name: "index_groups_sources_on_group_id"
    t.index ["source_id"], name: "index_groups_sources_on_source_id"
  end

  create_table "instance_associations", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
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

  create_table "record_links", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "source_instance_id"
    t.string "group_id"
    t.string "recordable_type"
    t.string "recordable_id"
    t.index ["group_id"], name: "index_record_links_on_group_id"
    t.index ["recordable_type", "recordable_id"], name: "index_record_links_on_recordable_type_and_recordable_id"
    t.index ["source_instance_id"], name: "index_record_links_on_source_instance_id"
  end

  create_table "rules", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "provider", null: false
    t.string "field", null: false
    t.string "operator", null: false
    t.json "value", null: false
    t.bigint "source_instance_id"
    t.bigint "board_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["board_id"], name: "index_rules_on_board_id"
    t.index ["source_instance_id"], name: "index_rules_on_source_instance_id"
  end

  create_table "settings", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "slug", null: false
    t.string "category", null: false
    t.string "key", null: false
    t.string "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_settings_on_slug", unique: true
  end

  create_table "source_instances", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "source_id"
    t.string "title"
    t.json "configuration"
    t.json "options"
    t.string "job_id"
    t.datetime "last_refresh"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["source_id"], name: "index_source_instances_on_source_id"
  end

  create_table "sources", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "active", default: true
    t.json "title", null: false
    t.string "compatibility"
    t.json "description", null: false
    t.string "creator"
    t.string "version", null: false
    t.string "homepage"
    t.string "icon"
    t.string "download", null: false
    t.string "slug", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_sources_on_slug", unique: true
  end

  create_table "system_states", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "variable", null: false
    t.json "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["variable"], name: "index_system_states_on_variable"
  end

  create_table "uploads", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "type", default: "Upload"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "widget_instances", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "widget_id"
    t.string "title"
    t.boolean "showtitle", default: false
    t.json "styles"
    t.json "configuration"
    t.json "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "board_id"
    t.string "type"
    t.index ["board_id"], name: "index_widget_instances_on_board_id"
    t.index ["widget_id"], name: "index_widget_instances_on_widget_id"
  end

  create_table "widgets", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.boolean "active", default: true
    t.json "title"
    t.string "compatibility"
    t.json "description"
    t.json "sizes"
    t.boolean "single_source", default: false
    t.string "version"
    t.string "creator"
    t.string "homepage"
    t.string "download"
    t.string "slug"
    t.string "icon"
    t.string "languages"
    t.string "group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_widgets_on_group_id"
    t.index ["slug"], name: "index_widgets_on_slug", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "boards", "uploads", column: "uploads_id"
  add_foreign_key "instance_associations", "groups", primary_key: "name"
  add_foreign_key "instance_associations", "source_instances"
  add_foreign_key "instance_associations", "widget_instances"
end
