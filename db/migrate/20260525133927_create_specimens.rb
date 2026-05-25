class CreateSpecimens < ActiveRecord::Migration[8.1]
  def change
    create_table :specimens do |t|
      t.string   :patient_id,           null: false
      t.string   :patient_name,         null: false
      t.date     :birth_date,           null: false
      t.string   :gender,               null: false
      t.string   :medical_record_id
      t.string   :lab_id,               null: false
      t.string   :order_number,         null: false
      t.string   :department
      t.datetime :collection_datetime
      t.string   :status,               null: false, default: "pending"
      t.datetime :completion_datetime

      t.timestamps
    end

    add_index :specimens, :patient_id
    add_index :specimens, :medical_record_id
    add_index :specimens, :lab_id
    add_index :specimens, :status
    add_index :specimens, :order_number, unique: true
  end
end
