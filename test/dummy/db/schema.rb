# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20171025075304) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "apidae_attached_files", force: :cascade do |t|
    t.string   "name"
    t.string   "credits"
    t.text     "description"
    t.integer  "apidae_object_id"
    t.string   "picture_file_name"
    t.string   "picture_content_type"
    t.integer  "picture_file_size"
    t.datetime "picture_updated_at"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
  end

  create_table "apidae_exports", force: :cascade do |t|
    t.string   "status"
    t.string   "remote_status"
    t.boolean  "oneshot"
    t.boolean  "reset"
    t.string   "file_url"
    t.string   "confirm_url"
    t.integer  "project_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "apidae_file_imports", force: :cascade do |t|
    t.string   "status"
    t.string   "remote_file"
    t.integer  "created"
    t.integer  "updated"
    t.integer  "deleted"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "apidae_objects", force: :cascade do |t|
    t.string   "address"
    t.integer  "apidae_id"
    t.string   "apidae_type"
    t.string   "apidae_subtype"
    t.string   "title"
    t.text     "short_desc"
    t.text     "contact"
    t.text     "long_desc"
    t.text     "type_data"
    t.float    "latitude"
    t.float    "longitude"
    t.text     "openings"
    t.text     "rates"
    t.text     "reservation"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "town_insee_code"
    t.text     "pictures_data"
    t.text     "entity_data"
  end

  create_table "apidae_objects_selections", force: :cascade do |t|
    t.integer "object_id"
    t.integer "selection_id"
  end

  create_table "apidae_selections", force: :cascade do |t|
    t.string   "label"
    t.string   "reference"
    t.integer  "apidae_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "apidae_towns", force: :cascade do |t|
    t.string   "country"
    t.integer  "apidae_id"
    t.string   "insee_code"
    t.string   "name"
    t.string   "postal_code"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "apidae_towns", ["insee_code"], name: "index_apidae_towns_on_insee_code", unique: true, using: :btree

end
