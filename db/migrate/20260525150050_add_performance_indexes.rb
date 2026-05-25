class AddPerformanceIndexes < ActiveRecord::Migration[8.1]
  def up
    # ── pg_trgm extension for fast ILIKE search ──────────────────────────────
    enable_extension "pg_trgm"

    # ── specimens ─────────────────────────────────────────────────────────────
    # Pagination sort — most queries order by created_at DESC
    add_index :specimens, :created_at

    # Composite index for filtered + sorted list (status filter + ORDER BY)
    add_index :specimens, [ :status, :created_at ]

    # GIN trigram indexes for ILIKE text search
    add_index :specimens, :patient_name, using: :gin,
              opclass: :gin_trgm_ops, name: "index_specimens_on_patient_name_trgm"
    add_index :specimens, :patient_id, using: :gin,
              opclass: :gin_trgm_ops, name: "index_specimens_on_patient_id_trgm"

    # ── works ─────────────────────────────────────────────────────────────────
    # Pagination sort
    add_index :works, :created_at

    # Composite for status filter + ORDER BY created_at
    add_index :works, [ :status, :created_at ]

    # Composite for specimen's works list (ordered by label_sequence)
    add_index :works, [ :specimen_id, :label_sequence ]

    # GIN trigram for barcode_id ILIKE search (exact already covered by unique index)
    add_index :works, :barcode_id, using: :gin,
              opclass: :gin_trgm_ops, name: "index_works_on_barcode_id_trgm"

    # ── examination_results ───────────────────────────────────────────────────
    # Composite — always queried by work_id, ordered by created_at
    add_index :examination_results, [ :work_id, :created_at ],
              name: "index_examination_results_on_work_id_created_at"
  end

  def down
    remove_index :specimens, :created_at
    remove_index :specimens, [ :status, :created_at ]
    remove_index :specimens, name: "index_specimens_on_patient_name_trgm"
    remove_index :specimens, name: "index_specimens_on_patient_id_trgm"

    remove_index :works, :created_at
    remove_index :works, [ :status, :created_at ]
    remove_index :works, [ :specimen_id, :label_sequence ]
    remove_index :works, name: "index_works_on_barcode_id_trgm"

    remove_index :examination_results, name: "index_examination_results_on_work_id_created_at"

    disable_extension "pg_trgm"
  end
end
