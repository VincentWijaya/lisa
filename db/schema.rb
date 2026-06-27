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

ActiveRecord::Schema[8.1].define(version: 2026_06_27_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "daily_sequences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "last_value", default: 0, null: false
    t.date "sequence_date", null: false
    t.datetime "updated_at", null: false
    t.index ["sequence_date"], name: "index_daily_sequences_on_sequence_date", unique: true
  end

  create_table "examination_results", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "entered_by"
    t.string "interpretation"
    t.bigint "reference_rule_id"
    t.string "result_unit"
    t.string "result_value", null: false
    t.string "source", null: false
    t.datetime "updated_at", null: false
    t.datetime "verified_at"
    t.bigint "verified_by"
    t.bigint "work_id", null: false
    t.index ["reference_rule_id"], name: "index_examination_results_on_reference_rule_id"
    t.index ["work_id", "created_at"], name: "index_examination_results_on_work_id_created_at"
    t.index ["work_id", "reference_rule_id", "created_at"], name: "index_examination_results_on_work_ref_rule_created_at"
    t.index ["work_id"], name: "index_examination_results_on_work_id"
  end

  create_table "examinations", force: :cascade do |t|
    t.string "category"
    t.string "code"
    t.datetime "created_at", null: false
    t.string "default_result_type"
    t.string "default_unit"
    t.text "description"
    t.string "label_group"
    t.string "name", null: false
    t.string "specimen_type"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_examinations_on_category"
    t.index ["code"], name: "index_examinations_on_code", unique: true, where: "(code IS NOT NULL)"
    t.index ["status"], name: "index_examinations_on_status"
  end

  create_table "reference_rules", force: :cascade do |t|
    t.jsonb "abnormal_values", default: [], null: false
    t.boolean "active", default: true, null: false
    t.jsonb "allowed_values", default: [], null: false
    t.datetime "created_at", null: false
    t.jsonb "critical_values", default: [], null: false
    t.text "description"
    t.bigint "examination_id", null: false
    t.string "gender"
    t.string "local_code"
    t.string "loinc_code"
    t.string "name", null: false
    t.jsonb "normal_values", default: [], null: false
    t.decimal "numeric_high_value", precision: 10, scale: 4
    t.decimal "numeric_low_value", precision: 10, scale: 4
    t.string "reference_value"
    t.string "result_type", null: false
    t.string "unit"
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_reference_rules_on_active"
    t.index ["examination_id", "active", "id"], name: "index_reference_rules_on_examination_active_id"
    t.index ["examination_id"], name: "index_reference_rules_on_examination_id"
    t.index ["gender"], name: "index_reference_rules_on_gender"
    t.index ["local_code"], name: "index_reference_rules_on_active_local_code", where: "((active = true) AND (local_code IS NOT NULL))"
    t.index ["local_code"], name: "index_reference_rules_on_local_code"
    t.index ["loinc_code"], name: "index_reference_rules_on_active_loinc_code", where: "((active = true) AND (loinc_code IS NOT NULL))"
    t.index ["loinc_code"], name: "index_reference_rules_on_loinc_code"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id", unique: true
    t.index ["name"], name: "index_roles_on_name"
    t.index ["resource_type", "resource_id"], name: "index_roles_on_resource"
  end

  create_table "specimens", force: :cascade do |t|
    t.string "affiliation"
    t.text "ai_summary"
    t.date "birth_date", null: false
    t.datetime "collection_datetime"
    t.datetime "completion_datetime"
    t.datetime "created_at", null: false
    t.string "department"
    t.text "dianognes"
    t.string "gender", null: false
    t.string "lab_id", null: false
    t.string "medical_record_id"
    t.string "order_number", null: false
    t.text "patient_address"
    t.string "patient_id", null: false
    t.string "patient_name", null: false
    t.string "referring_doctor"
    t.string "responsible_doctor"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_specimens_on_created_at"
    t.index ["lab_id"], name: "index_specimens_on_lab_id"
    t.index ["medical_record_id"], name: "index_specimens_on_medical_record_id"
    t.index ["medical_record_id"], name: "index_specimens_on_medical_record_id_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["order_number"], name: "index_specimens_on_order_number", unique: true
    t.index ["order_number"], name: "index_specimens_on_order_number_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["patient_id", "created_at"], name: "index_specimens_on_patient_id_and_created_at"
    t.index ["patient_id"], name: "index_specimens_on_patient_id"
    t.index ["patient_id"], name: "index_specimens_on_patient_id_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["patient_name"], name: "index_specimens_on_patient_name_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["status", "created_at"], name: "index_specimens_on_status_and_created_at"
    t.index ["status"], name: "index_specimens_on_status"
    t.index ["updated_at"], name: "index_specimens_on_updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "api_token"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["api_token"], name: "index_users_on_api_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.bigint "role_id", null: false
    t.bigint "user_id", null: false
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id", unique: true
    t.index ["user_id"], name: "index_users_roles_on_user_id"
  end

  create_table "works", force: :cascade do |t|
    t.text "ai_summary"
    t.string "barcode_id", null: false
    t.datetime "cancelled_at"
    t.datetime "created_at", null: false
    t.bigint "examination_id", null: false
    t.integer "label_sequence", default: 1, null: false
    t.boolean "manual_input", default: false, null: false
    t.datetime "sample_taken_datetime"
    t.bigint "specimen_id", null: false
    t.string "specimen_type"
    t.string "status", default: "pending", null: false
    t.string "test_codes_text"
    t.datetime "updated_at", null: false
    t.datetime "validated_at"
    t.datetime "verified_at"
    t.index ["barcode_id"], name: "index_works_on_barcode_id", unique: true
    t.index ["barcode_id"], name: "index_works_on_barcode_id_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["created_at"], name: "index_works_on_created_at"
    t.index ["examination_id"], name: "index_works_on_examination_id"
    t.index ["specimen_id", "examination_id", "status"], name: "index_works_on_specimen_id_examination_id_status"
    t.index ["specimen_id", "label_sequence"], name: "index_works_on_specimen_id_and_label_sequence"
    t.index ["specimen_id", "status"], name: "index_works_on_specimen_id_and_status"
    t.index ["specimen_id"], name: "index_works_on_specimen_id"
    t.index ["status", "created_at"], name: "index_works_on_status_and_created_at"
    t.index ["status"], name: "index_works_on_status"
    t.index ["updated_at"], name: "index_works_on_updated_at"
  end

  add_foreign_key "examination_results", "reference_rules"
  add_foreign_key "examination_results", "works"
  add_foreign_key "reference_rules", "examinations"
  add_foreign_key "users_roles", "roles"
  add_foreign_key "users_roles", "users"
  add_foreign_key "works", "examinations"
  add_foreign_key "works", "specimens"
end
