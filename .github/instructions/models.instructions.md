---
applyTo: "app/models/**/*.rb"
---

## Model conventions for LISA

- Enums must use string values: `enum :status, { pending: "pending", ... }, validate: true`
- Validations use `presence: true` for required fields, `inclusion:` for fixed sets
- Status transition rules are enforced via a `validate :status_transition_valid, if: :status_changed?` callback — never allow arbitrary transitions
- `has_many` with `dependent: :restrict_with_error` for associations that should not be silently cascade-deleted
- `has_many` with `dependent: :destroy` for child records that should be deleted with the parent
- `belongs_to` is required by default; use `optional: true` only when the FK is genuinely nullable
- No business logic in models — callbacks that trigger complex workflows belong in service objects
- JSONB array columns (`allowed_values`, etc.) should always default to `[]`
- The `Specimen` model requires the inflection fix in `config/initializers/inflections.rb`

### Naming
- Model files: `app/models/examination_result.rb` → class `ExaminationResult`
- Scope names are lowercase, descriptive: `scope :active, -> { where(status: :active) }`

### Adding a new enum value
1. Update the enum hash in the model
2. Write a migration only if using string storage and adding DB constraints (not needed for string enums)
3. Update any TRANSITIONS hash that guards status flow
4. Add a factory trait in `spec/factories/`
