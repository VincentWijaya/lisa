class CreateWorks < ActiveRecord::Migration[8.1]
  def change
    create_table :works do |t|
      t.string     :barcode_id,            null: false
      t.references :specimen,              null: false, foreign_key: { to_table: :specimens }
      t.references :examination,           null: false, foreign_key: { to_table: :examinations }
      t.datetime   :sample_taken_datetime
      t.boolean    :manual_input,          null: false, default: false
      t.string     :status,                null: false, default: "pending"
      t.integer    :label_sequence,        null: false, default: 1
      t.string     :specimen_type
      t.string     :test_codes_text
      t.datetime   :validated_at
      t.datetime   :verified_at
      t.datetime   :cancelled_at

      t.timestamps
    end

    add_index :works, :barcode_id, unique: true
    add_index :works, :status
  end
end
