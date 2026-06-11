---
applyTo: "app/controllers/api/**/*.rb,app/serializers/**/*.rb"
---

## API controller and serializer conventions for LISA

### API controllers
- Inherit from `Api::V1::BaseController`
- Set `respond_to :json` (or handle in base)
- Max ~10 lines per action — delegate all logic to a service object
- Standard action pattern:

```ruby
def create
  result = Specimens::CreateService.call(specimen_params)
  if result.success?
    render json: SpecimenSerializer.new(result.specimen).as_json, status: :created
  else
    render json: { errors: result.errors }, status: :unprocessable_content
  end
end
```

- Return codes: `201 :created`, `200 :ok`, `422 :unprocessable_content`, `404 :not_found`
- Never rescue exceptions in controllers — let `BaseController` handle common ones

### Custom member actions (validate, verify, cancel)
```ruby
def validate
  work = Work.find(params[:id])
  result = Works::ValidateService.call(work: work)
  if result.success?
    render json: WorkSerializer.new(result.work).as_json
  else
    render json: { errors: result.errors }, status: :unprocessable_content
  end
end
```

### Serializers
- Plain Ruby classes, no gem
- Output **camelCase** keys to match API spec
- Wrap complex serialization in a constructor: `Serializer.new(object).as_json`
- Nested associations are serialized inline (e.g. `works` array inside specimen response)
- Example key mapping: `barcode_id` → `barcodeId`, `patient_name` → `patientName`

### API response shape (specimens)
```json
{
  "id": 1,
  "patientId": "...",
  "patientName": "...",
  "birthDate": "YYYY-MM-DD",
  "gender": "...",
  "medicalRecordId": "...",
  "labId": "...",
  "orderNumber": "2605250001",
  "status": "pending",
  "works": [
    { "id": 1, "barcodeId": "2605250001-01", "examinationId": 1, "status": "pending", "labelSequence": 1 }
  ]
}
```

### Error response shape
```json
{ "errors": ["Patient ID can't be blank", "Examination 99 not found or inactive"] }
```
