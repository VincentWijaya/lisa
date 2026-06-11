# LISA — Agent Instructions

## Project Overview

LISA (Laboratory Information System Application) is a Ruby on Rails 8 app for managing lab specimens, work tasks, examinations, and results. It exposes a REST API under `/api/v1` and a Tailwind ERB web UI.

## Environment

- **Ruby**: 4.0.5
- **Rails**: 8.1.3
- **Database**: PostgreSQL 16 (requires `export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"`)
- **Test framework**: RSpec + FactoryBot + Shoulda Matchers
- **CSS**: Tailwind CSS
- **Admin**: Administrate at `/admin`

Always prefix database-related shell commands with:
```bash
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
```

## Common Commands

```bash
# Start dev server
bin/dev

# Run all tests
bundle exec rspec

# Run specific tests
bundle exec rspec spec/models/
bundle exec rspec spec/services/
bundle exec rspec spec/requests/

# Database
bundle exec rails db:migrate
bundle exec rails db:rollback
bundle exec rails db:migrate:status

# Routes
bundle exec rails routes | grep api

# Console
bundle exec rails console

# Zeitwerk (autoload check)
bundle exec rails zeitwerk:check
```

## Architecture Rules

### Service Objects
- All business logic lives in `app/services/`
- Namespaced by domain: `Specimens::CreateService`, `Works::ValidateService`
- Every service uses the `ServiceResult` pattern:
  ```ruby
  ServiceResult.success(specimen: specimen)
  ServiceResult.failure(errors: ["reason"])
  ```
- Call via `.call(params)` class method
- Controllers call the service and render from the result — never put logic in controllers

### Serializers
- Plain Ruby classes in `app/serializers/`
- Output camelCase JSON keys to match API spec
- No gem dependency (no `active_model_serializers`, no `alba`, etc.)

### Controllers
- API controllers inherit from `Api::V1::BaseController`
- Max ~10 lines per action — delegate to service, render via serializer
- Return `201` for creates, `200` for updates, `422` for validation errors, `404` for not found

### Models
- String-backed enums only (not integer)
- All status transitions validated via custom `validate` callback
- No business logic in models — use service objects

## Domain Model

```
Examination  ──< ReferenceRule
Examination  ──< Work
Specimen     ──< Work
Work         ──< ExaminationResult
ExaminationResult >── ReferenceRule (optional)
```

### Status Flows
```
Work:    pending → validated → verified
         pending → cancelled
         validated → cancelled

Specimen: pending → in_progress → complete
          (auto-completes when all works are verified)
```

### Barcode ID Format
```
YYMMDD + 4-digit daily sequence + "-" + 2-digit label sequence
Example: 2605250054-01
```

`order_number` is generated in `Specimens::CreateService` as `YYMMDD + format('%04d', today_count + 1)`.
`barcode_id` is generated in `Works::BarcodeGenerator` as `"#{order_number}-#{format('%02d', label_sequence)}"`.

### Label Grouping
Examinations with the same `label_group` share ONE work record. Their codes are joined: `"GLU-Slik; UR; CRE;"`. Examinations with no `label_group` (or unique group) each get their own work record.

## Key Inflection Fix

`config/initializers/inflections.rb` must contain:
```ruby
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.irregular "specimen", "specimens"
end
```
Rails treats "specimen" as uncountable. Without this fix, `Specimen.table_name` returns `"specimen"` (singular), causing DB errors.

## Git Conventions

- Commit after each logical step
- Commit message format: `short description\n\nDetailed bullet points`

## Testing Conventions

- Factories in `spec/factories/` — use FactoryBot `create` for DB-backed, `build` for unit tests
- Model specs: test enums, validations, associations, custom methods
- Service specs: test happy path, validation errors, transaction rollback
- Request specs: test full API response shape + status codes
- Use `shoulda-matchers` for association and validation one-liners

## JSONB Fields

`reference_rules` has four JSONB arrays:
- `allowed_values` — all valid result values (empty = any value allowed)
- `normal_values` — values considered normal
- `abnormal_values` — values considered abnormal
- `critical_values` — values considered critical

Always default to `[]`, never `nil`.

## Adding New Features — Checklist

1. Migration (if schema change needed)
2. Model with validations + associations
3. Service object in `app/services/`
4. Serializer in `app/serializers/`
5. Controller action (thin)
6. Route
7. RSpec: model spec + service spec + request spec
8. Git commit
