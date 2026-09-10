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

ActiveRecord::Schema[8.1].define(version: 2026_09_10_000515) do
  create_table "admin_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_admin_sessions_on_user_id"
  end

  create_table "appointments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "customer_id", null: false
    t.datetime "ends_at", null: false
    t.text "notes"
    t.integer "service_offering_id", null: false
    t.datetime "starts_at", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_appointments_on_customer_id"
    t.index ["service_offering_id", "status", "starts_at"], name: "index_appointments_on_offering_status_start"
    t.index ["service_offering_id"], name: "index_appointments_on_service_offering_id"
    t.check_constraint "starts_at < ends_at", name: "appointments_ordered_times"
    t.check_constraint "status IN (0, 1, 2)", name: "appointments_valid_status"
  end

  create_table "availabilities", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.integer "day_of_week", null: false
    t.time "end_time", null: false
    t.integer "staff_member_id", null: false
    t.time "start_time", null: false
    t.datetime "updated_at", null: false
    t.index ["staff_member_id", "day_of_week", "active"], name: "idx_on_staff_member_id_day_of_week_active_b6808e1b79"
    t.index ["staff_member_id"], name: "index_availabilities_on_staff_member_id"
    t.check_constraint "active IN (0, 1)", name: "availabilities_valid_active"
    t.check_constraint "day_of_week BETWEEN 0 AND 6", name: "availabilities_valid_day"
    t.check_constraint "start_time < end_time", name: "availabilities_ordered_times"
  end

  create_table "service_offerings", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.integer "service_id", null: false
    t.integer "staff_member_id", null: false
    t.datetime "updated_at", null: false
    t.index ["service_id"], name: "index_service_offerings_on_service_id"
    t.index ["staff_member_id", "service_id"], name: "index_service_offerings_on_staff_member_id_and_service_id", unique: true
    t.index ["staff_member_id"], name: "index_service_offerings_on_staff_member_id"
    t.check_constraint "active IN (0, 1)", name: "service_offerings_valid_active"
  end

  create_table "services", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "duration_minutes", null: false
    t.string "name", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index "lower(name)", name: "index_services_on_normalized_name", unique: true
    t.check_constraint "active IN (0, 1)", name: "services_valid_active"
    t.check_constraint "duration_minutes > 0", name: "services_positive_duration"
    t.check_constraint "price >= 0", name: "services_nonnegative_price"
  end

  create_table "staff_members", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "email_address"
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.index "lower(email_address)", name: "index_staff_members_on_normalized_email", unique: true
    t.check_constraint "active IN (0, 1)", name: "staff_members_valid_active"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "password_digest", null: false
    t.string "phone"
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index "lower(email_address)", name: "index_users_on_normalized_email", unique: true
    t.check_constraint "active IN (0, 1)", name: "users_valid_active"
    t.check_constraint "role IN (0, 1)", name: "users_valid_role"
  end

  add_foreign_key "admin_sessions", "users"
  add_foreign_key "appointments", "service_offerings"
  add_foreign_key "appointments", "users", column: "customer_id"
  add_foreign_key "availabilities", "staff_members"
  add_foreign_key "service_offerings", "services"
  add_foreign_key "service_offerings", "staff_members"
end
