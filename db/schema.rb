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

ActiveRecord::Schema[8.1].define(version: 2026_05_25_134115) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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
    t.index ["work_id"], name: "index_examination_results_on_work_id"
  end

  create_table "examinations", force: :cascade do |t|
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
    t.index ["examination_id"], name: "index_reference_rules_on_examination_id"
    t.index ["loinc_code"], name: "index_reference_rules_on_loinc_code"
  end

  create_table "specimens", force: :cascade do |t|
    t.date "birth_date", null: false
    t.datetime "collection_datetime"
    t.datetime "completion_datetime"
    t.datetime "created_at", null: false
    t.string "department"
    t.string "gender", null: false
    t.string "lab_id", null: false
    t.string "medical_record_id"
    t.string "order_number", null: false
    t.string "patient_id", null: false
    t.string "patient_name", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["lab_id"], name: "index_specimens_on_lab_id"
    t.index ["medical_record_id"], name: "index_specimens_on_medical_record_id"
    t.index ["order_number"], name: "index_specimens_on_order_number", unique: true
    t.index ["patient_id"], name: "index_specimens_on_patient_id"
    t.index ["status"], name: "index_specimens_on_status"
  end

  create_table "works", force: :cascade do |t|
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
    t.index ["examination_id"], name: "index_works_on_examination_id"
    t.index ["specimen_id"], name: "index_works_on_specimen_id"
    t.index ["status"], name: "index_works_on_status"
  end

  add_foreign_key "examination_results", "reference_rules"
  add_foreign_key "examination_results", "works"
  add_foreign_key "reference_rules", "examinations"
  add_foreign_key "works", "examinations"
  add_foreign_key "works", "specimens"
end
