class CreateExaminationResults < ActiveRecord::Migration[8.1]
  def change
    create_table :examination_results do |t|
      t.references :work,           null: false, foreign_key: { to_table: :works }
      t.string     :result_value,   null: false
      t.string     :result_unit
      t.bigint     :reference_rule_id
      t.string     :interpretation
      t.string     :source,         null: false
      t.bigint     :entered_by
      t.bigint     :verified_by
      t.datetime   :verified_at

      t.timestamps
    end

    add_index :examination_results, :reference_rule_id
  end
end
