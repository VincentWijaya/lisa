class AddScaleIndexesAndDailySequences < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def up
    create_table :daily_sequences, if_not_exists: true do |t|
      t.date :sequence_date, null: false
      t.integer :last_value, null: false, default: 0
      t.timestamps
    end

    add_index :daily_sequences, :sequence_date, unique: true,
              name: "index_daily_sequences_on_sequence_date",
              if_not_exists: true,
              algorithm: :concurrently

    backfill_daily_sequences

    add_index :specimens, :updated_at,
              if_not_exists: true,
              algorithm: :concurrently
    add_index :specimens, [ :patient_id, :created_at ],
              name: "index_specimens_on_patient_id_and_created_at",
              if_not_exists: true,
              algorithm: :concurrently
    add_index :specimens, :medical_record_id,
              using: :gin,
              opclass: :gin_trgm_ops,
              name: "index_specimens_on_medical_record_id_trgm",
              if_not_exists: true,
              algorithm: :concurrently
    add_index :specimens, :order_number,
              using: :gin,
              opclass: :gin_trgm_ops,
              name: "index_specimens_on_order_number_trgm",
              if_not_exists: true,
              algorithm: :concurrently

    add_index :works, :updated_at,
              if_not_exists: true,
              algorithm: :concurrently
    add_index :works, [ :specimen_id, :status ],
              name: "index_works_on_specimen_id_and_status",
              if_not_exists: true,
              algorithm: :concurrently
    add_index :works, [ :specimen_id, :examination_id, :status ],
              name: "index_works_on_specimen_id_examination_id_status",
              if_not_exists: true,
              algorithm: :concurrently

    add_index :reference_rules, [ :examination_id, :active, :id ],
              name: "index_reference_rules_on_examination_active_id",
              if_not_exists: true,
              algorithm: :concurrently
    add_index :reference_rules, :loinc_code,
              name: "index_reference_rules_on_active_loinc_code",
              where: "active = true AND loinc_code IS NOT NULL",
              if_not_exists: true,
              algorithm: :concurrently
    add_index :reference_rules, :local_code,
              name: "index_reference_rules_on_active_local_code",
              where: "active = true AND local_code IS NOT NULL",
              if_not_exists: true,
              algorithm: :concurrently

    add_index :examination_results, [ :work_id, :reference_rule_id, :created_at ],
              name: "index_examination_results_on_work_ref_rule_created_at",
              if_not_exists: true,
              algorithm: :concurrently
  end

  def down
    remove_index :examination_results,
                 name: "index_examination_results_on_work_ref_rule_created_at",
                 if_exists: true,
                 algorithm: :concurrently

    remove_index :reference_rules,
                 name: "index_reference_rules_on_active_local_code",
                 if_exists: true,
                 algorithm: :concurrently
    remove_index :reference_rules,
                 name: "index_reference_rules_on_active_loinc_code",
                 if_exists: true,
                 algorithm: :concurrently
    remove_index :reference_rules,
                 name: "index_reference_rules_on_examination_active_id",
                 if_exists: true,
                 algorithm: :concurrently

    remove_index :works,
                 name: "index_works_on_specimen_id_examination_id_status",
                 if_exists: true,
                 algorithm: :concurrently
    remove_index :works,
                 name: "index_works_on_specimen_id_and_status",
                 if_exists: true,
                 algorithm: :concurrently
    remove_index :works,
                 column: :updated_at,
                 if_exists: true,
                 algorithm: :concurrently

    remove_index :specimens,
                 name: "index_specimens_on_order_number_trgm",
                 if_exists: true,
                 algorithm: :concurrently
    remove_index :specimens,
                 name: "index_specimens_on_medical_record_id_trgm",
                 if_exists: true,
                 algorithm: :concurrently
    remove_index :specimens,
                 name: "index_specimens_on_patient_id_and_created_at",
                 if_exists: true,
                 algorithm: :concurrently
    remove_index :specimens,
                 column: :updated_at,
                 if_exists: true,
                 algorithm: :concurrently

    remove_index :daily_sequences,
                 name: "index_daily_sequences_on_sequence_date",
                 if_exists: true,
                 algorithm: :concurrently
    drop_table :daily_sequences, if_exists: true
  end

  private

  def backfill_daily_sequences
    execute <<~SQL.squish
      INSERT INTO daily_sequences (sequence_date, last_value, created_at, updated_at)
      SELECT sequence_date, MAX(sequence_value), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM (
        SELECT
          to_date(SUBSTRING(order_number FROM 1 FOR 6), 'YYMMDD') AS sequence_date,
          SUBSTRING(order_number FROM 7 FOR 4)::integer AS sequence_value
        FROM specimens
        WHERE order_number ~ '^[0-9]{10}$'
      ) existing_sequences
      GROUP BY sequence_date
      ON CONFLICT (sequence_date) DO UPDATE
      SET last_value = GREATEST(daily_sequences.last_value, EXCLUDED.last_value),
          updated_at = CURRENT_TIMESTAMP
    SQL
  end
end
