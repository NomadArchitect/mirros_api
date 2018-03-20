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

ActiveRecord::Schema.define(version: 20180315105336) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.string "website"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "categories_groups", id: false, force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "category_id", null: false
  end

  create_table "categories_sources", id: false, force: :cascade do |t|
    t.bigint "source_id", null: false
    t.bigint "category_id", null: false
  end

  create_table "categories_widgets", id: false, force: :cascade do |t|
    t.bigint "category_id", null: false
    t.bigint "widget_id", null: false
  end

  create_table "groups", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "groups_sources", id: false, force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "source_id", null: false
  end

  create_table "groups_widgets", id: false, force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "widget_id", null: false
  end

  create_table "instances", force: :cascade do |t|
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "services", force: :cascade do |t|
    t.string "status"
    t.json "parameters"
    t.integer "widget_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["widget_id"], name: "index_services_on_widget_id"
  end

  create_table "source_instances", force: :cascade do |t|
    t.integer "source_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["source_id"], name: "index_source_instances_on_source_id"
  end

  create_table "sources", force: :cascade do |t|
    t.string "name"
    t.string "creator"
    t.string "version"
    t.string "website"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "widget_instances", force: :cascade do |t|
    t.integer "widget_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["widget_id"], name: "index_widget_instances_on_widget_id"
  end

  create_table "widgets", force: :cascade do |t|
    t.string "name"
    t.string "icon"
    t.string "version"
    t.string "creator"
    t.string "website"
    t.string "languages", default: ["en_GB"], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
