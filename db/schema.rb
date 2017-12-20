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

ActiveRecord::Schema.define(version: 20171220174632) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "blorgh_articles", force: :cascade do |t|
    t.string "title"
    t.text "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.string "website"
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "categories_components", id: false, force: :cascade do |t|
    t.bigint "component_id", null: false
    t.bigint "category_id", null: false
  end

  create_table "categories_groups", id: false, force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "category_id", null: false
  end

  create_table "categories_sources", id: false, force: :cascade do |t|
    t.bigint "source_id", null: false
    t.bigint "category_id", null: false
  end

  create_table "component_instances", force: :cascade do |t|
    t.integer "component_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "components", force: :cascade do |t|
    t.string "name"
    t.string "author"
    t.string "version"
    t.string "website"
    t.string "repository"
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "components_groups", id: false, force: :cascade do |t|
    t.bigint "component_id", null: false
    t.bigint "group_id", null: false
  end

  create_table "groups", force: :cascade do |t|
    t.string "name"
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "groups_sources", id: false, force: :cascade do |t|
    t.bigint "group_id", null: false
    t.bigint "source_id", null: false
  end

  create_table "instances", force: :cascade do |t|
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "netatmo_entries", force: :cascade do |t|
    t.string "name"
    t.text "text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "source_instances", force: :cascade do |t|
    t.integer "source_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sources", force: :cascade do |t|
    t.string "name"
    t.string "author"
    t.string "version"
    t.string "website"
    t.string "repository"
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
