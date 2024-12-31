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

ActiveRecord::Schema[7.2].define(version: 2024_12_31_150727) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "appointment_types", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "appointments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "dependent_id", null: false
    t.bigint "dentist_id", null: false
    t.bigint "appointment_type_id", null: false
    t.datetime "appointment_time"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_type_id"], name: "index_appointments_on_appointment_type_id"
    t.index ["dentist_id"], name: "index_appointments_on_dentist_id"
    t.index ["dependent_id"], name: "index_appointments_on_dependent_id"
    t.index ["user_id"], name: "index_appointments_on_user_id"
  end

  create_table "dentists", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "specialty"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "dependents", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "first_name"
    t.string "last_name"
    t.date "date_of_birth"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_dependents_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "password_digest", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "appointments", "appointment_types"
  add_foreign_key "appointments", "dentists"
  add_foreign_key "appointments", "dependents"
  add_foreign_key "appointments", "users"
  add_foreign_key "dependents", "users"
end
