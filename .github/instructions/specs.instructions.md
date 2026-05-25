---
applyTo: "spec/**/*.rb"
---

## RSpec testing conventions for LISA

### Setup
- Tests use RSpec + FactoryBot + Shoulda Matchers + Faker
- `spec/rails_helper.rb` configures FactoryBot and Shoulda Matchers
- Run all tests: `bundle exec rspec`
- Run a single file: `bundle exec rspec spec/models/work_spec.rb`

### Factory conventions
Factories live in `spec/factories/`. One file per model.

```ruby
FactoryBot.define do
  factory :examination do
    name { Faker::Science.element }
    code { Faker::Alphanumeric.alpha(number: 6).upcase }
    status { "active" }
    default_result_type { "numeric" }
  end
end
```

Traits for enum variants:
```ruby
trait :inactive do
  status { "inactive" }
end
```

Always use `create` for DB-backed tests, `build` for pure unit tests.

### Model spec conventions
- Use `shoulda-matchers` for associations and validations:
  ```ruby
  it { is_expected.to belong_to(:specimen) }
  it { is_expected.to validate_presence_of(:barcode_id) }
  ```
- Test enum values explicitly
- Test status transition guards (valid and invalid transitions)
- Test custom methods (e.g. `age_in_years`, `interpretation_for`)

### Service spec conventions
- Test via `.call(params)` interface only (treat as a black box)
- Always test the happy path
- Always test validation failure paths
- For transactional services (e.g. `Specimens::CreateService`), verify rollback:
  ```ruby
  expect { subject }.not_to change(Work, :count)
  ```

### Request spec conventions
- Use `spec/requests/api/v1/` for API specs
- POST with JSON body: `post url, params: payload.to_json, headers: { "Content-Type" => "application/json" }`
- Assert both status code and response body shape:
  ```ruby
  expect(response).to have_http_status(:created)
  expect(json["patientId"]).to eq("12345")
  expect(json["works"].length).to eq(3)
  ```
- Helper: `let(:json) { JSON.parse(response.body) }`

### What to test for each new feature
1. Model spec — validations, associations, enum values, custom methods
2. Service spec — happy path, error path, transaction rollback (if applicable)
3. Request spec — status codes, response JSON shape, error response shape

### Before committing
```bash
bundle exec rspec
bundle exec rails zeitwerk:check
```
