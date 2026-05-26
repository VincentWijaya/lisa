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
| Auth | `has_secure_password` + `rolify` |
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
| **User** | A system user with one or more roles. Authenticates via email + password. |
| **Role** | Grants access permissions. Four roles: `admin`, `lab_supervisor`, `lab_technician`, `doctor`. |

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

# Seed master data + default users
bin/rails db:seed

# Start the development server
bin/dev
```

The app will be available at `http://localhost:3000`. Log in with any of the seeded accounts below.

---

## Authentication & Roles

All web UI pages require login. The admin backoffice additionally requires the `admin` role.

### Seeded accounts (password: `Password@123`)

| Email | Role | Access |
|---|---|---|
| `admin@lisa.local` | `admin` | Full access + admin backoffice |
| `supervisor@lisa.local` | `lab_supervisor` | Web UI — can verify works |
| `tech1@lisa.local` | `lab_technician` | Web UI — can validate works and enter results |
| `tech2@lisa.local` | `lab_technician` | Web UI — can validate works and enter results |
| `doctor@lisa.local` | `doctor` | Web UI — read-only access |

### Roles

| Role | Description |
|---|---|
| `admin` | Full system access. Manages users and roles via `/admin`. |
| `lab_supervisor` | Can verify completed works. |
| `lab_technician` | Can validate works and submit examination results. |
| `doctor` | Read-only access to results and specimens. |

### Managing users & roles

Visit `/admin/users` and `/admin/roles` (requires `admin` account) to:
- Create or deactivate users
- Assign roles to users

---

## Seed Data

Running `bin/rails db:seed` creates:

- **22 examinations** across panels: Chemistry (CHEM), Lipid (LIPID), Liver Function (LFT), Serology (SERO), Thyroid (THYROID), Hematology, Urinalysis
- **24 reference rules** with numeric reference ranges (with LOINC codes) and qualitative value sets
- **5 sample patients** with works
- **5 users** (one per role)

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
│   │   ├── application_controller.rb   # requires admin role
│   │   ├── examinations_controller.rb
│   │   ├── examination_results_controller.rb
│   │   ├── reference_rules_controller.rb
│   │   ├── specimens_controller.rb
│   │   ├── works_controller.rb
│   │   ├── users_controller.rb
│   │   └── roles_controller.rb
│   ├── works/
│   │   └── examination_results_controller.rb  # web UI result verify/update/delete
│   ├── sessions_controller.rb          # login / logout
│   ├── dashboard_controller.rb
│   ├── specimens_controller.rb
│   └── works_controller.rb
├── models/
│   ├── user.rb              # has_secure_password, rolify
│   ├── role.rb              # rolify role model
│   ├── examination.rb
│   ├── examination_result.rb
│   ├── reference_rule.rb
│   ├── specimen.rb
│   └── work.rb
├── dashboards/              # Administrate dashboard configs
├── serializers/             # Plain Ruby camelCase JSON serializers
│   ├── specimen_serializer.rb
│   ├── work_serializer.rb
│   └── examination_result_serializer.rb
└── services/                # Business logic service objects
    ├── service_result.rb
    ├── auth/
    │   └── login_service.rb
    ├── specimens/
    │   └── create_service.rb
    ├── examination_results/
    │   ├── create_service.rb
    │   ├── update_service.rb
    │   └── verify_service.rb
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
users               → has_and_belongs_to_many roles (via users_roles)
roles               → has_and_belongs_to_many users
examinations        → has_many works, reference_rules
specimens           → has_many works
works               → belongs_to specimen, examination
                      has_many examination_results
examination_results → belongs_to work, reference_rule
reference_rules     → belongs_to examination
```

### Key fields

**users**
- `email` — unique, downcased
- `password_digest` — bcrypt via `has_secure_password`
- `api_token` — auto-generated 64-char hex token
- `active` — boolean; inactive users cannot log in

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

### Specimens

```
GET  /api/v1/specimens          # list all specimens
GET  /api/v1/specimens/:id      # show a specimen
POST /api/v1/specimens          # create a specimen (with works)
```

**Create request body:**
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

### Works

```
GET   /api/v1/works             # list all works
GET   /api/v1/works/:id         # show a work
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
| `/login` | Login page |
| `/` | Dashboard — summary cards + recent activity |
| `/works` | Work list with filters (status, lab, search) and action buttons |
| `/works/:id` | Work detail + result input |
| `/specimens` | Specimen list |
| `/specimens/:id` | Specimen detail with all works |
| `/works/:id/barcode_label` | Printable barcode label |
| `/specimens/:id/barcode_labels` | All printable labels for specimen |
| `/admin` | Administrate backoffice (admin only) |

---

## Admin Backoffice

Visit `/admin` (requires `admin` account) to manage all master data and user access:

- **Users** — create accounts, set passwords, activate/deactivate
- **Roles** — view and manage role assignments
- **Examinations** — create, activate/deactivate, set `specimen_type` + `label_group`
- **Reference Rules** — configure `allowed_values`, `normal_values`, `abnormal_values`, `critical_values`
- **Specimens**, **Works**, **Examination Results** — view and edit

---

## Running Tests

```bash
bundle exec rspec                   # all tests (73 examples)
bundle exec rspec spec/models       # model specs
bundle exec rspec spec/services     # service specs
bundle exec rspec spec/requests     # API + session request specs
```

---

## Architecture Notes

- **Service objects** (`app/services/`) contain all business logic. Controllers are thin (~5 lines per action).
- **Serializers** (`app/serializers/`) are plain Ruby classes that produce camelCase JSON — no external serializer gem needed.
- **`ServiceResult`** — all services return a result object with `success?`, `failure?`, `errors`, and a data payload.
- **Transactions** — specimen creation runs in a DB transaction; if any work fails to create, the whole operation rolls back.
- **JSONB** — `reference_rules` uses PostgreSQL JSONB for `allowed_values`, `normal_values`, `abnormal_values`, and `critical_values` — flexible configuration without schema changes.
- **Inflection fix** — `config/initializers/inflections.rb` registers `specimen → specimens` because ActiveSupport treats "specimen" as uncountable by default.
- **Authentication** — session-based using `has_secure_password`. No Devise. `ApplicationController` provides `authenticate_user!` and `require_role!` helpers.
- **RBAC** — powered by `rolify`. Roles are assigned per-user and checked with `has_role?(:role_name)`. Admin backoffice requires the `admin` role.
