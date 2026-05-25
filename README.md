# LISA — Laboratory Information System Application

LISA is a Laboratory Information System for managing specimens, examinations, work tasks, and examination results. It supports both quantitative results (e.g. `14.6 g/dL`) and qualitative results (e.g. `NON REACTIVE`, `DETECTED`).

---

## Tech Stack

| Layer | Technology |
|---|---|
| Backend | Ruby 4.0.5 / Rails 8.1.3 |
| Database | PostgreSQL 16 |
| Frontend | ERB + Hotwire/Turbo + Tailwind CSS |
| Admin UI | Administrate (`/admin`) |
| API | JSON REST under `/api/v1` |
| Barcodes | Barby + ChunkyPNG (Code 128) |
| Tests | RSpec + FactoryBot + Shoulda Matchers |
| Background Jobs | Solid Queue |

---

## Core Concepts

| Concept | Description |
|---|---|
| **Specimen** | One lab order for a patient. Contains patient info, selected examinations, and overall status. |
| **Work** | One actionable lab task generated from a specimen + examination. Has a unique barcode. |
| **Examination** | Master data for a lab test (CBC, HBsAg, Glucose, etc.). |
| **ExaminationResult** | The actual result value for a work record (stored as string). |
| **ReferenceRule** | Defines how a result is interpreted — numeric ranges or qualitative value lists. |

---

## Getting Started

### Prerequisites

- Ruby 4.0.5
- PostgreSQL 16
- Bundler

### Setup

```bash
# Clone and install dependencies
git clone <repo-url>
cd lisa
bundle install

# Set up the database
bin/rails db:create db:migrate

# Start the development server
bin/dev
```

The app will be available at `http://localhost:3000`.

---

## Project Structure

```
app/
├── controllers/
│   ├── api/v1/              # JSON REST API controllers
│   │   ├── base_controller.rb
│   │   ├── specimens_controller.rb
│   │   └── works_controller.rb
│   ├── admin/               # Administrate backoffice controllers
│   ├── dashboard_controller.rb
│   ├── specimens_controller.rb
│   └── works_controller.rb
├── models/
│   ├── examination.rb
│   ├── examination_result.rb
│   ├── reference_rule.rb
│   ├── specimen.rb
│   └── work.rb
├── serializers/             # Plain Ruby camelCase JSON serializers
│   ├── specimen_serializer.rb
│   ├── work_serializer.rb
│   └── examination_result_serializer.rb
└── services/                # Business logic service objects
    ├── service_result.rb
    ├── specimens/
    │   └── create_service.rb
    ├── examination_results/
    │   └── create_service.rb
    └── works/
        ├── barcode_generator.rb
        ├── work_creation_service.rb
        ├── label_data_service.rb
        ├── validate_service.rb
        ├── verify_service.rb
        └── cancel_service.rb
```

---

## Database Schema

```
examinations        → has_many works, reference_rules
specimens           → has_many works
works               → belongs_to specimen, examination
                      has_many examination_results
examination_results → belongs_to work, reference_rule
reference_rules     → belongs_to examination
```

### Key fields

**specimens**
- `patient_id`, `patient_name`, `birth_date`, `gender`, `lab_id` — required
- `order_number` — unique daily sequence, e.g. `2605250001` (`YYMMDD` + 4-digit counter)
- `status` — `pending` | `in_progress` | `complete` | `cancelled`

**works**
- `barcode_id` — unique, e.g. `2605250001-01`
- `label_sequence` — position within the specimen's work labels
- `specimen_type` — snapshot from examination (e.g. `EDTA`, `SERUM/PLASMA`)
- `test_codes_text` — snapshot of codes (e.g. `GLU-Slik; UR; CRE;`)
- `status` — `pending` → `validated` → `verified` | `cancelled`

**reference_rules**
- `result_type` — `numeric` | `qualitative` | `text`
- `allowed_values`, `normal_values`, `abnormal_values`, `critical_values` — JSONB arrays
- `numeric_low_value`, `numeric_high_value` — for numeric ranges

---

## API Reference

All API endpoints are under `/api/v1` and return JSON.

### Create Specimen

```
POST /api/v1/specimens
```

**Request:**
```json
{
  "patientId": "12345",
  "patientName": "Jane Doe",
  "birthDate": "1990-05-15",
  "gender": "Female",
  "medicalRecordId": "MR-2026-0001",
  "labId": "LAB01",
  "examinationIds": [1, 2, 3]
}
```

**Response `201`:**
```json
{
  "id": 1,
  "patientId": "12345",
  "patientName": "Jane Doe",
  "orderNumber": "2605250001",
  "status": "pending",
  "works": [
    { "id": 1, "barcodeId": "2605250001-01", "examinationId": 1, "status": "pending", "labelSequence": 1 }
  ]
}
```

**Response `422`:**
```json
{ "errors": ["Examination 99 not found or inactive"] }
```

### Work Actions

```
PATCH /api/v1/works/:id/validate   # pending → validated
PATCH /api/v1/works/:id/verify     # validated → verified (auto-completes specimen when all works verified)
PATCH /api/v1/works/:id/cancel     # pending|validated → cancelled
```

### Submit Result

```
POST /api/v1/works/:id/results
```

```json
{
  "resultValue": "NON REACTIVE",
  "referenceRuleId": 2,
  "source": "manual"
}
```

### Barcode Label

```
GET /api/v1/works/:id/barcode_label   # JSON label data
GET /works/:id/barcode_label          # Printable HTML label
GET /specimens/:id/barcode_labels     # All labels for a specimen (HTML)
```

---

## Barcode ID Format

```
YYMMDD + daily_sequence (4 digits) + "-" + label_sequence (2 digits)
```

Example: `2605250054-01`

| Part | Value | Meaning |
|---|---|---|
| `260525` | date | 25 May 2026 |
| `0054` | sequence | 54th specimen that day |
| `01` | label | 1st work label |

### Label Grouping

Examinations sharing the same `label_group` are combined into one work record and one barcode label:

| Examination | Code | Label Group |
|---|---|---|
| Glucose | `GLU-Slik` | `CHEMISTRY_SERUM` |
| Ureum | `UR` | `CHEMISTRY_SERUM` |
| CBC Diff | `CBC__DIFF` | `HEMATOLOGY_EDTA` |

Generates: `2605250001-01 → CBC__DIFF;` and `2605250001-02 → GLU-Slik; UR;`

---

## Status Flows

### Work Status
```
pending → validated → verified
pending → cancelled
validated → cancelled
```

### Specimen Status
```
pending → in_progress → complete
pending → cancelled
```

Specimen becomes `complete` automatically when **all** related works are `verified`.

---

## Result Interpretation

**Qualitative** (via `reference_rule`):
- Value in `normal_values` → `normal`
- Value in `abnormal_values` → `abnormal`
- Value in `critical_values` → `critical`
- Value not in `allowed_values` → validation error

**Numeric** (via `reference_rule`):
- Within `numeric_low_value`–`numeric_high_value` → `normal`
- Outside range → `abnormal`

---

## UI Pages

| Path | Description |
|---|---|
| `/` | Dashboard — summary cards + recent activity |
| `/works` | Work list with filters (status, lab, search) and action buttons |
| `/works/:id` | Work detail + result input |
| `/specimens` | Specimen list |
| `/specimens/:id` | Specimen detail with all works |
| `/works/:id/barcode_label` | Printable barcode label |
| `/specimens/:id/barcode_labels` | All printable labels for specimen |
| `/admin` | Administrate backoffice |

---

## Admin Backoffice

Visit `/admin` to manage all master data:
- **Examinations** — create, activate/deactivate, set `specimen_type` + `label_group`
- **Reference Rules** — configure `allowed_values`, `normal_values`, `abnormal_values`, `critical_values`
- **Specimens**, **Works**, **Examination Results** — view and edit

---

## Running Tests

```bash
bundle exec rspec                   # all tests (50 examples)
bundle exec rspec spec/models       # model specs
bundle exec rspec spec/services     # service specs
bundle exec rspec spec/requests     # API request specs
```

---

## Architecture Notes

- **Service objects** (`app/services/`) contain all business logic. Controllers are thin (~5 lines per action).
- **Serializers** (`app/serializers/`) are plain Ruby classes that produce camelCase JSON — no external serializer gem needed.
- **`ServiceResult`** — all services return a result object with `success?`, `failure?`, `errors`, and a data payload.
- **Transactions** — specimen creation runs in a DB transaction; if any work fails to create, the whole operation rolls back.
- **JSONB** — `reference_rules` uses PostgreSQL JSONB for `allowed_values`, `normal_values`, `abnormal_values`, and `critical_values` — flexible configuration without schema changes.
- **Inflection fix** — `config/initializers/inflections.rb` registers `specimen → specimens` because ActiveSupport treats "specimen" as uncountable by default.
