---
applyTo: "app/services/**/*.rb"
---

## Service object conventions for LISA

### Structure
Every service class follows this template:

```ruby
module Domain
  class ActionService
    def self.call(params)
      new(params).call
    end

    def initialize(params)
      @params = params
      @errors = []
    end

    def call
      validate_inputs
      return ServiceResult.failure(errors: @errors) if @errors.any?

      # ... do work ...

      ServiceResult.success(key: result)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure(errors: e.record.errors.full_messages)
    end

    private

    attr_reader :params, :errors
  end
end
```

### Rules
- Always place services under a domain namespace: `Specimens::`, `Works::`, `ExaminationResults::`
- Services live in `app/services/<domain>/<action>_service.rb`
- Multi-record writes must be wrapped in `ActiveRecord::Base.transaction { ... }`
- Raise `ActiveRecord::Rollback` inside a transaction to abort without bubbling an exception
- Use `ServiceResult.success(...)` and `ServiceResult.failure(errors: [...])` for return values
- Never call `render` or access `params` from ActionController inside a service
- Never call another service's private methods — compose via `.call`

### ServiceResult
`app/services/service_result.rb` — a simple value object:
- `result.success?` / `result.failure?`
- `result.errors` → array of strings
- `result.data` or named readers (e.g. `result.specimen`)

### Naming
- `Specimens::CreateService` — creates a specimen + works
- `Works::ValidateService` — transitions work pending → validated
- `Works::VerifyService` — transitions work validated → verified, auto-completes specimen
- `Works::CancelService` — cancels a work
- `Works::BarcodeGenerator` — generates barcode_id + label metadata
- `Works::WorkCreationService` — creates work records for a specimen, respects label_group
- `Works::LabelDataService` — builds printable label hash for a work record
- `ExaminationResults::CreateService` — records a result, sets interpretation
