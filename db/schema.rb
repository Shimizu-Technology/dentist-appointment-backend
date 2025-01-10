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

ActiveRecord::Schema[7.2].define(version: 2025_01_09_135531) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "appointment_reminders", force: :cascade do |t|
    t.bigint "appointment_id", null: false
    t.datetime "send_at", null: false
    t.boolean "sent", default: false
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_id"], name: "index_appointment_reminders_on_appointment_id"
  end

  create_table "appointment_types", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "duration"
  end

  create_table "appointments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "dependent_id"
    t.bigint "dentist_id", null: false
    t.bigint "appointment_type_id", null: false
    t.datetime "appointment_time"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "notes"
    t.boolean "checked_in", default: false, null: false
    t.index ["appointment_type_id"], name: "index_appointments_on_appointment_type_id"
    t.index ["dentist_id"], name: "index_appointments_on_dentist_id"
    t.index ["dependent_id"], name: "index_appointments_on_dependent_id"
    t.index ["user_id"], name: "index_appointments_on_user_id"
  end

  create_table "clinic_settings", force: :cascade do |t|
    t.string "open_time", default: "09:00", null: false
    t.string "close_time", default: "17:00", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "open_days", default: "1,2,3,4,5", null: false
  end

  create_table "closed_days", force: :cascade do |t|
    t.date "date", null: false
    t.string "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_closed_days_on_date", unique: true
  end

  create_table "dentist_unavailabilities", force: :cascade do |t|
    t.bigint "dentist_id", null: false
    t.string "start_time", null: false
    t.string "end_time", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "date", null: false
    t.string "reason"
    t.index ["dentist_id"], name: "index_dentist_unavailabilities_on_dentist_id"
  end

  create_table "dentists", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "specialty_id"
    t.string "image_url"
    t.text "qualifications"
    t.index ["specialty_id"], name: "index_dentists_on_specialty_id"
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

  create_table "specialties", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: ""
    t.string "password_digest", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role"
    t.string "provider_name"
    t.string "policy_number"
    t.string "plan_type"
    t.string "phone"
    t.string "first_name"
    t.string "last_name"
    t.boolean "force_password_reset", default: false, null: false
    t.string "invitation_token"
    t.datetime "invitation_sent_at"
    t.index ["email"], name: "index_users_on_email", unique: true, where: "(email IS NOT NULL)"
  end

  add_foreign_key "appointment_reminders", "appointments"
  add_foreign_key "appointments", "appointment_types"
  add_foreign_key "appointments", "dentists"
  add_foreign_key "appointments", "dependents"
  add_foreign_key "appointments", "users"
  add_foreign_key "dentist_unavailabilities", "dentists"
  add_foreign_key "dentists", "specialties"
  add_foreign_key "dependents", "users"
end
