# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2023_02_06_113335) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "apidae_exports", id: :serial, force: :cascade do |t|
    t.string "status"
    t.string "remote_status"
    t.boolean "oneshot"
    t.boolean "reset"
    t.string "file_url"
    t.string "confirm_url"
    t.integer "project_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "apidae_file_imports", id: :serial, force: :cascade do |t|
    t.string "status"
    t.string "remote_file"
    t.integer "created"
    t.integer "updated"
    t.integer "deleted"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "apidae_id"
  end

  create_table "apidae_objects_selections", id: :serial, force: :cascade do |t|
    t.integer "object_id"
    t.integer "selection_id"
  end

  create_table "apidae_objs", id: :serial, force: :cascade do |t|
    t.integer "apidae_id"
    t.string "apidae_type"
    t.string "apidae_subtype"
    t.jsonb "contact_data"
    t.jsonb "type_data"
    t.jsonb "openings_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "town_insee_code"
    t.jsonb "pictures_data"
    t.jsonb "entity_data"
    t.jsonb "service_data"
    t.jsonb "rates_data"
    t.jsonb "attachments_data"
    t.jsonb "tags_data"
    t.jsonb "meta_data"
    t.jsonb "location_data"
    t.jsonb "description_data"
    t.jsonb "title_data"
    t.jsonb "booking_data"
    t.string "version"
    t.integer "root_obj_id"
    t.datetime "last_update"
    t.jsonb "owner_data"
    t.jsonb "version_data"
    t.jsonb "prev_data"
    t.index ["apidae_id"], name: "apidae_objs_apidae_id"
    t.index ["root_obj_id", "version"], name: "index_apidae_objs_on_root_obj_id_and_version", unique: true
    t.index ["root_obj_id"], name: "apidae_objs_root_obj_id"
    t.index ["town_insee_code"], name: "index_apidae_objs_on_town_insee_code"
  end

  create_table "apidae_projects", force: :cascade do |t|
    t.string "name"
    t.integer "apidae_id"
    t.string "api_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "locales_data"
    t.string "versions_data"
  end

  create_table "apidae_references", force: :cascade do |t|
    t.integer "apidae_id"
    t.string "apidae_type"
    t.jsonb "label_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "meta_data"
    t.boolean "is_active"
    t.index ["apidae_id"], name: "index_apidae_references_on_apidae_id"
    t.index ["apidae_type"], name: "index_apidae_references_on_apidae_type"
    t.index ["is_active"], name: "index_apidae_references_on_is_active"
  end

  create_table "apidae_selection_objects", force: :cascade do |t|
    t.integer "apidae_selection_id"
    t.integer "apidae_object_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "apidae_selections", id: :serial, force: :cascade do |t|
    t.string "label"
    t.string "reference"
    t.integer "apidae_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "apidae_project_id"
  end

  create_table "apidae_territories", force: :cascade do |t|
    t.integer "apidae_id"
    t.string "name"
    t.integer "apidae_type"
    t.index ["apidae_id"], name: "index_apidae_territories_on_apidae_id"
  end

  create_table "apidae_towns", id: :serial, force: :cascade do |t|
    t.string "country"
    t.integer "apidae_id"
    t.string "insee_code"
    t.string "name"
    t.string "postal_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "description"
    t.index ["insee_code"], name: "index_apidae_towns_on_insee_code"
  end

end
