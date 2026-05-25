class CreateReferenceRules < ActiveRecord::Migration[8.1]
  def change
    create_table :reference_rules do |t|
      t.references :examination,      null: false, foreign_key: { to_table: :examinations }
      t.string     :loinc_code
      t.string     :name,             null: false
      t.text       :description
      t.string     :unit
      t.string     :result_type,      null: false
      t.string     :reference_value
      t.jsonb      :allowed_values,   null: false, default: []
      t.jsonb      :normal_values,    null: false, default: []
      t.jsonb      :abnormal_values,  null: false, default: []
      t.jsonb      :critical_values,  null: false, default: []
      t.decimal    :numeric_low_value,  precision: 10, scale: 4
      t.decimal    :numeric_high_value, precision: 10, scale: 4
      t.boolean    :active,           null: false, default: true

      t.timestamps
    end

    add_index :reference_rules, :loinc_code
    add_index :reference_rules, :active
  end
end
