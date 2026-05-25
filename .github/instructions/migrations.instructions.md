---
applyTo: "db/migrate/**/*.rb,db/schema.rb"
---

## Database migration conventions for LISA

### General rules
- Always add `null: false` for required columns
- Always add `default:` for boolean and status columns
- String enums: store as `string`, not `integer`
- `status` columns: `t.string :status, null: false, default: "pending"`
- JSONB columns: `t.jsonb :allowed_values, null: false, default: []`
- Decimal precision: `precision: 10, scale: 4` for lab measurement values

### Foreign keys
- When using `t.references`, Rails may try to resolve the FK table name. Specify explicitly:
  ```ruby
  t.references :specimen, null: false, foreign_key: { to_table: :specimens }
  ```
- Optional FKs (nullable): omit `null: false`, add `optional: true` on the model's `belongs_to`

### Indexes
- Every `_id` foreign key column gets an index automatically via `t.references`
- Add explicit indexes for columns used in filters/searches:
  - `specimens`: patient_id, medical_record_id, lab_id, status, order_number (unique)
  - `works`: barcode_id (unique), status
  - `examination_results`: work_id, reference_rule_id
  - `reference_rules`: examination_id, loinc_code, active

### Naming conventions
- Migration class: `CreateSpecimens`, `AddDepartmentToSpecimens`, `AddReferenceRuleFkToExaminationResults`
- Migration file: auto-generated timestamp prefix by Rails generator

### After adding a migration
```bash
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
bundle exec rails db:migrate
bundle exec rails db:migrate RAILS_ENV=test
```

### Rollback
```bash
bundle exec rails db:rollback        # one step
bundle exec rails db:rollback STEP=3 # three steps
```

### Inflection note
`specimen` → `specimens` is registered as an irregular inflection. Do not rename the `specimens` table. If you add a new model whose name Rails cannot pluralize correctly, add an entry to `config/initializers/inflections.rb`.
