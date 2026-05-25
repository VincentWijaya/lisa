# LISA — Repository-Wide Copilot Instructions

## What this project is

LISA is a Ruby on Rails 8 Laboratory Information System. It manages lab specimens, work tasks, examinations, and results. There is a REST JSON API under `/api/v1` and a Tailwind CSS web UI.

## Always follow these rules

- Use **service objects** for all business logic (`app/services/`). Never put logic in controllers or models.
- Use **plain Ruby serializers** (`app/serializers/`) for JSON output. Output keys in **camelCase**.
- Use **string-backed enums** — never integer enums.
- Use **`ServiceResult`** pattern: `ServiceResult.success(data:)` / `ServiceResult.failure(errors: [...])`.
- Wrap specimen creation (and any multi-record writes) in a **database transaction**.
- `result_value` on `ExaminationResult` is always stored as a **string**, even for numeric results.
- JSONB columns (`allowed_values`, `normal_values`, `abnormal_values`, `critical_values`) must default to `[]`, never `nil`.
- The inflection fix `inflect.irregular "specimen", "specimens"` in `config/initializers/inflections.rb` must never be removed.
- API controllers inherit from `Api::V1::BaseController`.

## PostgreSQL path

When running any shell command that touches the database, prefix with:
```bash
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
```

## Code style

- Thin controllers: max ~10 lines per action.
- No comments on obvious code. Only comment non-obvious logic.
- Always run `bundle exec rails zeitwerk:check` after adding new files.
- Always run `bundle exec rspec` before committing.
