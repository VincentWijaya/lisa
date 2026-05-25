# LISA - Laboratory Information System Application

## 1. Overview

**LISA** is a Laboratory Information System Application for managing laboratory specimens, examinations, work tasks, and examination results. The system should support both quantitative laboratory results, such as `14.6 g/dL`, and qualitative/string-based results, such as `NON REACTIVE`, `REACTIVE`, `POSITIVE`, `NEGATIVE`, `DETECTED`, or `NOT DETECTED`.

The application should be built with Ruby on Rails and PostgreSQL, with a simple web interface for laboratory staff and REST API endpoints for integration with external systems.

## 2. Recommended Technology Stack

| Area | Recommendation |
| --- | --- |
| Backend | Ruby on Rails |
| Database | PostgreSQL |
| Admin/Internal UI | Rails Administrate or ActiveAdmin |
| Custom UI | ERB templates with Hotwire/Turbo for a fast first version |
| Styling | Bootstrap or Tailwind CSS |
| API Format | JSON REST API |
| Tests | RSpec |
| Background Jobs | Sidekiq or Rails Active Job, if external result fetching is asynchronous |

### Frontend Recommendation

For the first version, use **Rails ERB + Hotwire/Turbo** instead of React. The workflows are mostly CRUD-heavy and operational, so Rails views will be faster to build and easier to maintain. React can be added later only for complex interactive screens, such as live instrument monitoring or advanced dashboards.

## 3. Core Concepts

### 3.1 Specimen

A specimen represents one laboratory order/request for a patient. It contains patient information, the target lab, selected examinations, and overall completion status.

### 3.2 Work

A work record represents one actionable lab task generated from a specimen and an examination. A specimen can generate multiple work records.

Example: if a specimen is created with three examination IDs, the system should automatically create three work records.

### 3.3 Examination

An examination is the master data for a laboratory test that can be ordered, such as Hemoglobin, HBsAg, Glucose, or PCR SARS-CoV-2.

### 3.4 Examination Result

An examination result stores the actual result value for a work record. The result value must be stored as a string so it can support numeric, qualitative, and free-text results.

### 3.5 Reference Rule

A reference rule defines how a result should be interpreted. It replaces the old idea of only storing `lowValue` and `highValue`.

This is important because not all lab results are numeric. Some tests use dynamic string values such as:

- `NON REACTIVE` / `REACTIVE`
- `NEGATIVE` / `POSITIVE`
- `NOT DETECTED` / `DETECTED`
- `NORMAL` / `ABNORMAL`

## 4. Features

## 4.1 Dashboard

Create a simple landing dashboard with placeholder or real summary data.

Recommended dashboard cards:

- Total specimens today
- Pending work tasks
- Validated work tasks
- Verified/completed work tasks
- Cancelled work tasks
- Recent specimens
- Recent abnormal/reactive results

For the first version, dummy data is acceptable. Later, replace it with real database queries.

## 4.2 Specimen Tracking

The system must allow users or external systems to create specimen records.

### Specimen Fields

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `patient_id` | string | Yes | External patient identifier |
| `patient_name` | string | Yes | Patient full name |
| `birth_date` | date | Yes | Patient birth date |
| `gender` | string | Yes | Prefer configurable values instead of hard-coded values |
| `medical_record_id` | string | No | Can be manually input or auto-generated |
| `lab_id` | string | Yes | Lab performing the examination |
| `status` | enum | Yes | `pending`, `in_progress`, `complete`, `cancelled` |
| `completion_datetime` | datetime | No | Set when all work tasks are verified |
| `created_at` | datetime | Yes | Rails managed |
| `updated_at` | datetime | Yes | Rails managed |

### Specimen Creation Logic

When a specimen is created:

1. Validate that all submitted examination IDs exist and are active.
2. Create the specimen record.
3. Automatically generate one work record for each examination ID.
4. Generate a unique barcode ID for each work record.
5. Return the created specimen and generated work records in the API response.

The full operation should run inside a database transaction. If one work record fails to be created, the specimen creation should be rolled back.

## 4.3 Work Data

Work records are generated automatically when a specimen is created.

### Work Fields

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `barcode_id` | string | Yes | Unique barcode for the task |
| `specimen_id` | reference | Yes | Belongs to specimen |
| `examination_id` | reference | Yes | Belongs to examination |
| `sample_taken_datetime` | datetime | No | Time sample was collected |
| `manual_input` | boolean | Yes | `true` if result was entered manually |
| `status` | enum | Yes | `pending`, `validated`, `verified`, `cancelled` |
| `validated_at` | datetime | No | Set when status becomes `validated` |
| `verified_at` | datetime | No | Set when status becomes `verified` |
| `cancelled_at` | datetime | No | Set when status becomes `cancelled` |
| `created_at` | datetime | Yes | Rails managed |
| `updated_at` | datetime | Yes | Rails managed |

### Recommended Status Flow

Use clear status names:

```text
pending -> validated -> verified
pending -> cancelled
validated -> cancelled
```

Avoid using `verified=complete` as a status value. A work task should be `verified`; the specimen becomes `complete` only when all related work tasks are verified.

### Barcode Generation Recommendation

Barcode generation should follow the printable laboratory label format described in **4.4.1 Barcode Label Printing Specification**.

Recommended format:

```text
YYMMDD + daily_order_sequence + work_or_tube_suffix
```

Example:

```text
2605150054-01
2605150054-04
```

This format is compact enough for small specimen labels and still traceable by collection/order date.

## 4.4 Work List

Create a work list page for laboratory staff.

### Required Features

- Display all work records.
- Show barcode ID, patient name, examination name, status, and created date.
- Filter by status.
- Filter by lab ID.
- Filter by examination.
- Search by barcode ID, patient ID, medical record ID, or patient name.
- Button to move work from `pending` to `validated`.
- Result input form.
- Button to verify a completed/validated work task.
- Button to cancel a work task.
- Barcode printing support.

### Recommended Columns

| Column | Description |
| --- | --- |
| Barcode ID | Unique task barcode |
| Patient | Patient name and patient ID |
| Examination | Test name |
| Result | Current result value, if available |
| Interpretation | Normal, abnormal, reactive, etc. |
| Status | Work status |
| Created At | Work created date |
| Actions | Validate, input result, verify, cancel, print barcode |



## 4.4.1 Barcode Label Printing Specification

Barcode printing should support small laboratory specimen labels similar to real lab stickers. The label must be compact, readable, and printable on thermal barcode printers.

### Label Purpose

Each printed barcode label is used to identify either:

1. A **specimen-level label**, representing the whole specimen/order.
2. A **work-level label**, representing a specific examination group or tube/container.

In most workflows, the system should print one label per work record because each work record has its own `barcode_id`.

### Recommended Label Format

The label should contain these sections from top to bottom:

```text
[Specimen Type / Container] [Collection Date Time]
[Barcode Image]
[Barcode ID]
[Patient Name]
[Medical Record ID / Age / Gender / Birth Date]
[Examination Codes or Test Group]
[Ward / Room / Department]
```

### Example Label Layout

```text
SERUM/PLASMA (15-05-2026 10:27:32)
||||||||||||||||||||||||||||||||||||||||
2605150054-04
SUNARTO, TN
877023/68 Thn /L/13-12-1957
GLU-Slik; UR; CRE;
PERAWATAN IGD
```

Another example for a different work task from the same specimen:

```text
EDTA (15-05-2026 10:27:32)
||||||||||||||||||||||||||||||||||||||||
2605150054-01
SUNARTO, TN
877023/68 Thn /L/13-12-1957
CBC__DIFF;
PERAWATAN IGD
```

### Barcode ID Recommendation

The barcode value should be short enough to fit on a small label but still traceable.

Recommended format:

```text
YYMMDD + running_number + suffix
```

Example:

```text
2605150054-04
```

Meaning:

| Part | Example | Meaning |
| --- | --- | --- |
| `260515` | `260515` | Date in `YYMMDD` format |
| `0054` | `0054` | Daily specimen/order sequence |
| `-04` | `-04` | Work/tube/examination sequence |

For a specimen-level barcode, the suffix can be omitted:

```text
2605150054
```

For work-level barcode labels, include the suffix:

```text
2605150054-01
2605150054-02
2605150054-03
```

### Barcode Label Fields

Add these printable fields to the work label output. Some fields can come from related models instead of being stored directly on `works`.

| Label Field | Source | Required | Notes |
| --- | --- | --- | --- |
| `barcode_id` | `works.barcode_id` | Yes | Value encoded in the barcode image |
| `specimen_type` | examination/work configuration | Yes | Example: `SERUM/PLASMA`, `EDTA` |
| `collection_datetime` | `works.sample_taken_datetime` or specimen collection time | Yes | Printed on the top line |
| `patient_name` | `specimens.patient_name` | Yes | Print uppercase if possible |
| `medical_record_id` | `specimens.medical_record_id` | Yes | Example: `877023` |
| `age` | calculated from `birth_date` | Yes | Example: `68 Thn` |
| `gender` | `specimens.gender` | Yes | Example: `L` / `P` or configured values |
| `birth_date` | `specimens.birth_date` | Yes | Example: `13-12-1957` |
| `test_codes` | examinations linked to the work/container | Yes | Example: `GLU-Slik; UR; CRE;` |
| `department` | order/specimen location | No | Example: `PERAWATAN IGD` |

### Additional Database Fields for Barcode Printing

To support the label format, add or derive these fields.

#### Specimens Table Additions

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `order_number` | string | Yes | Daily specimen/order number, example: `2605150054` |
| `department` | string | No | Ward, room, clinic, or source department |
| `collection_datetime` | datetime | No | Default collection time for generated work labels |

#### Works Table Additions

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `barcode_id` | string | Yes | Example: `2605150054-01` |
| `label_sequence` | integer | Yes | Example: `1`, `2`, `3` |
| `specimen_type` | string | No | Snapshot for printing, example: `EDTA` |
| `test_codes_text` | string | No | Snapshot for printing, example: `CBC__DIFF;` |

#### Examinations Table Additions

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `code` | string | No | Short code printed on label, example: `CBC__DIFF` |
| `specimen_type` | string | No | Default container/specimen type, example: `EDTA` |
| `label_group` | string | No | Used to group examinations into the same tube/label |

### Label Grouping Rule

Some examinations can share one tube/container and one barcode label. The system should support grouping work labels by `label_group` or `specimen_type`.

Example:

| Examination | Code | Specimen Type | Label Group |
| --- | --- | --- | --- |
| Glucose | `GLU-Slik` | `SERUM/PLASMA` | `CHEMISTRY_SERUM` |
| Ureum | `UR` | `SERUM/PLASMA` | `CHEMISTRY_SERUM` |
| Creatinine | `CRE` | `SERUM/PLASMA` | `CHEMISTRY_SERUM` |
| CBC Diff | `CBC__DIFF` | `EDTA` | `HEMATOLOGY_EDTA` |

Expected generated labels:

```text
2605150054-01 -> EDTA -> CBC__DIFF;
2605150054-04 -> SERUM/PLASMA -> GLU-Slik; UR; CRE;
```

This means barcode generation should not always be one label per examination. It should be configurable:

- **Simple mode:** one work record and one barcode label per examination.
- **Grouped mode:** one printable work/container label can represent multiple examinations in the same `label_group`.

### Barcode Printing UI Requirements

On the work list and specimen detail pages, provide:

- Print single barcode label.
- Print all labels for one specimen.
- Reprint barcode label with audit log.
- Preview label before printing.
- Select printer or label template if multiple printers/templates exist.

### Barcode Technical Recommendation

Use a 1D barcode for the first version, such as Code 128, because it is compact and works well for alphanumeric IDs like `2605150054-04`.

Recommended implementation options:

- Generate barcode image/SVG using a Ruby barcode library.
- Render the label as HTML/CSS for browser printing.
- Use a dedicated print endpoint for thermal printer labels.
- Keep the printed barcode value exactly the same as `works.barcode_id`.

### Suggested Print Endpoint

```http
GET /works/:id/barcode_label
```

Returns an HTML label preview/print page.

```http
GET /specimens/:id/barcode_labels
```

Returns all barcode labels for one specimen.

For API usage:

```http
GET /api/v1/works/:id/barcode_label
```

Optional response:

```json
{
  "barcodeId": "2605150054-04",
  "specimenType": "SERUM/PLASMA",
  "collectionDateTime": "2026-05-15T10:27:32+07:00",
  "patientName": "SUNARTO, TN",
  "medicalRecordId": "877023",
  "ageText": "68 Thn",
  "gender": "L",
  "birthDate": "1957-12-13",
  "testCodesText": "GLU-Slik; UR; CRE;",
  "department": "PERAWATAN IGD"
}
```


## 4.5 Examination Results

The system must store examination results for work tasks.

### Examination Result Fields

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `work_id` | reference | Yes | Belongs to work |
| `result_value` | string | Yes | Store all result values as string |
| `result_unit` | string | No | Optional snapshot from reference rule/examination |
| `reference_rule_id` | reference | No | Rule used to interpret the result |
| `interpretation` | string | No | Example: `normal`, `abnormal`, `reactive`, `non_reactive` |
| `source` | enum | Yes | `manual`, `external_api`, `instrument` |
| `entered_by` | reference/user | No | User who entered result manually |
| `verified_by` | reference/user | No | User who verified the result |
| `verified_at` | datetime | No | Verification timestamp |
| `created_at` | datetime | Yes | Rails managed |
| `updated_at` | datetime | Yes | Rails managed |

### Important Design Decision

`result_value` should remain a string even for numeric results.

Examples:

```text
14.6
NON REACTIVE
REACTIVE
< 0.05
> 1000
NOT DETECTED
Sample hemolyzed
```

This makes the system flexible enough for real laboratory data.

## 4.6 Reference Rules for Examination Results

The previous `ReferenceRange` concept should be renamed to **ReferenceRule** or **ResultReference** because not all references are numeric ranges.

Recommended model name:

```text
ReferenceRule
```

### Reference Rule Fields

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `examination_id` | reference | Yes | Rule belongs to an examination |
| `loinc_code` | string | No | LOINC code for the test/result |
| `name` | string | Yes | Example: Hemoglobin, HBsAg |
| `description` | text | No | Description of the rule |
| `unit` | string | No | Example: `g/dL`; blank for qualitative tests |
| `result_type` | enum/string | Yes | `numeric`, `qualitative`, `text` |
| `reference_value` | string | No | Human-readable reference value |
| `allowed_values` | jsonb | No | Dynamic list of allowed string values |
| `normal_values` | jsonb | No | Dynamic list of normal values |
| `abnormal_values` | jsonb | No | Dynamic list of abnormal values |
| `critical_values` | jsonb | No | Optional values considered critical |
| `numeric_low_value` | decimal | No | Only used when `result_type = numeric` |
| `numeric_high_value` | decimal | No | Only used when `result_type = numeric` |
| `active` | boolean | Yes | Allows old rules to be disabled |
| `created_at` | datetime | Yes | Rails managed |
| `updated_at` | datetime | Yes | Rails managed |

### Why This Is Better Than Only `lowValue` and `highValue`

A fixed numeric range only works for tests like Hemoglobin:

```text
13.00 - 17.00 g/dL
```

It does not work well for qualitative tests like HBsAg:

```text
NON REACTIVE / REACTIVE
```

Using string and JSONB fields allows each examination to define its own valid result values dynamically.

### Example Reference Rules

| id | examination | result_type | unit | reference_value | allowed_values | normal_values | abnormal_values |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Hemoglobin | numeric | g/dL | 13.00 - 17.00 | [] | [] | [] |
| 2 | HBsAg | qualitative | | NON REACTIVE | `["NON REACTIVE", "REACTIVE"]` | `["NON REACTIVE"]` | `["REACTIVE"]` |
| 3 | SARS-CoV-2 PCR | qualitative | | NOT DETECTED | `["NOT DETECTED", "DETECTED"]` | `["NOT DETECTED"]` | `["DETECTED"]` |

## 4.7 Examination Master Data

The system must provide master data for examinations that can be ordered.

### Examination Fields

| Field | Type | Required | Notes |
| --- | --- | --- | --- |
| `name` | string | Yes | Examination name |
| `code` | string | No | Internal code |
| `description` | text | No | Description |
| `default_unit` | string | No | Optional default unit |
| `default_result_type` | string | No | `numeric`, `qualitative`, `text` |
| `status` | enum | Yes | `active`, `inactive` |
| `created_at` | datetime | Yes | Rails managed |
| `updated_at` | datetime | Yes | Rails managed |

## 5. API Requirements

## 5.1 Create Specimen

```http
POST /api/v1/specimens
```

### Request Payload

```json
{
  "patientId": "12345",
  "patientName": "Jane Doe",
  "birthDate": "1990-05-15",
  "gender": "Female",
  "medicalRecordId": "MR-2026-0001",
  "examinationIds": [1, 2, 3],
  "labId": "LAB123"
}
```

### Success Response

```json
{
  "id": 1,
  "patientId": "12345",
  "patientName": "Jane Doe",
  "birthDate": "1990-05-15",
  "gender": "Female",
  "medicalRecordId": "MR-2026-0001",
  "labId": "LAB123",
  "status": "pending",
  "works": [
    {
      "id": 1,
      "barcodeId": "LAB123-20260525-0001",
      "examinationId": 1,
      "status": "pending"
    },
    {
      "id": 2,
      "barcodeId": "LAB123-20260525-0002",
      "examinationId": 2,
      "status": "pending"
    }
  ]
}
```

### Validation Rules

- `patientId`, `patientName`, `birthDate`, `gender`, `labId`, and `examinationIds` are required.
- `examinationIds` must not be empty.
- Every examination ID must exist and have `status = active`.
- The creation process must be transactional.

## 5.2 Validate Work

```http
PATCH /api/v1/works/:id/validate
```

This endpoint changes a work task from `pending` to `validated`.

### Success Response

```json
{
  "id": 1,
  "barcodeId": "LAB123-20260525-0001",
  "status": "validated",
  "validatedAt": "2026-05-25T12:00:00Z"
}
```

## 5.3 Input Result

```http
POST /api/v1/works/:id/results
```

### Request Payload for Numeric Result

```json
{
  "resultValue": "14.6",
  "referenceRuleId": 1,
  "source": "manual"
}
```

### Request Payload for Qualitative Result

```json
{
  "resultValue": "NON REACTIVE",
  "referenceRuleId": 2,
  "source": "manual"
}
```

### Validation Rules

- `resultValue` is required.
- `resultValue` must be stored as a string.
- If the reference rule has `allowed_values`, the result must match one of those values.
- If the result is outside the configured normal values or numeric range, mark interpretation accordingly.

## 5.4 Verify Work

```http
PATCH /api/v1/works/:id/verify
```

This endpoint verifies the work task. After verification, the system should check whether all work tasks for the related specimen are verified.

If all related work tasks are verified, update the specimen status to `complete` and set `completion_datetime`.

## 5.5 Cancel Work

```http
PATCH /api/v1/works/:id/cancel
```

### Request Payload

```json
{
  "reason": "Sample damaged"
}
```

Cancelling a work task should not automatically complete the specimen unless the business rule explicitly allows specimens with cancelled work to be completed.

## 6. Database Schema Recommendation

## 6.1 Tables

Recommended tables:

- `specimens`
- `examinations`
- `works`
- `examination_results`
- `reference_rules`
- `users` for authentication and audit trail, optional for first version

## 6.2 Important Indexes

Add database indexes for:

- `specimens.patient_id`
- `specimens.medical_record_id`
- `specimens.lab_id`
- `specimens.status`
- `works.barcode_id`, unique
- `works.specimen_id`
- `works.examination_id`
- `works.status`
- `examination_results.work_id`
- `reference_rules.examination_id`
- `reference_rules.loinc_code`

## 6.3 PostgreSQL JSONB Usage

Use JSONB fields for dynamic values:

```ruby
allowed_values: :jsonb, default: []
normal_values: :jsonb, default: []
abnormal_values: :jsonb, default: []
critical_values: :jsonb, default: []
```

This supports flexible configuration without schema changes.

## 7. Business Rules

## 7.1 Specimen Completion

A specimen should become `complete` only when all related work records are `verified`.

Recommended logic:

```text
if specimen.works.all? { |work| work.status == "verified" }
  specimen.status = "complete"
  specimen.completion_datetime = Time.current
end
```

## 7.2 Result Interpretation

For qualitative results:

- If `result_value` is included in `normal_values`, interpretation should be `normal`.
- If `result_value` is included in `abnormal_values`, interpretation should be `abnormal`.
- If `result_value` is included in `critical_values`, interpretation should be `critical`.
- If `allowed_values` is present and result does not match, return validation error.

For numeric results:

- Parse `result_value` as decimal only when `result_type = numeric`.
- Compare against `numeric_low_value` and `numeric_high_value` when available.
- If parsing fails, return validation error or mark as free-text depending on the business rule.

## 7.3 Audit Trail

Recommended audit fields:

- `created_by`
- `updated_by`
- `validated_by`
- `verified_by`
- `cancelled_by`

For the first version, these can be optional. For production, they are strongly recommended.

## 8. UI Pages

## 8.1 Dashboard

Path:

```text
/
```

Displays summary cards and recent activity.

## 8.2 Specimens

Path:

```text
/specimens
```

Features:

- List specimens
- Create specimen
- View specimen details
- Show generated work tasks
- Show completion status

## 8.3 Work List

Path:

```text
/works
```

Features:

- Work task table
- Filters
- Result input
- Validation and verification buttons
- Barcode printing

## 8.4 Examinations

Path:

```text
/examinations
```

Features:

- Manage examination master data
- Set active/inactive status

## 8.5 Reference Rules

Path:

```text
/reference_rules
```

Features:

- Manage numeric and qualitative reference rules
- Configure allowed values dynamically
- Configure normal and abnormal values dynamically

## 9. Testing Requirements

Use RSpec for model, request, and service tests.

### Model Tests

- Specimen validates required fields.
- Work validates unique barcode ID.
- Examination only allows valid statuses.
- Reference rule supports numeric and qualitative configurations.
- Examination result validates against allowed qualitative values.

### API Tests

- Create specimen successfully creates work records.
- Create specimen rolls back when examination ID is invalid.
- Validate work changes status correctly.
- Input numeric result stores value as string.
- Input qualitative result accepts configured values.
- Input qualitative result rejects values outside `allowed_values`.
- Verify final work task completes the specimen.

### Service Tests

Recommended service objects:

- `Specimens::CreateWithWorks`
- `Works::GenerateBarcode`
- `Results::InterpretResult`
- `Works::VerifyAndCompleteSpecimen`

## 10. Expected Output

The completed application should include:

1. Rails models:
   - `Specimen`
   - `Examination`
   - `Work`
   - `ExaminationResult`
   - `ReferenceRule`
2. Rails controllers:
   - `Api::V1::SpecimensController`
   - `Api::V1::WorksController`
   - `Api::V1::ExaminationResultsController`
   - `ExaminationsController`
   - `ReferenceRulesController`
3. UI pages:
   - Dashboard
   - Specimen tracking
   - Work list
   - Result input
   - Examination master data
   - Reference rule master data
4. REST API endpoints for:
   - Specimen creation
   - Work validation
   - Result input
   - Work verification
   - Work cancellation
5. PostgreSQL migrations.
6. RSpec tests.
7. Barcode printing functionality.

## 11. Additional Suggestions

### 11.1 Rename `ReferenceRange` to `ReferenceRule`

`ReferenceRange` sounds numeric-only. `ReferenceRule` is more accurate because the system supports both numeric ranges and string-based reference values.

### 11.2 Use Snake Case in Rails Internally

Use Rails convention internally:

```text
patient_id
patient_name
birth_date
lab_id
```

Use camelCase only in JSON API responses if required by frontend or external integration:

```text
patientId
patientName
birthDate
labId
```

### 11.3 Keep Result Value as String

Do not store result values only as decimals. Real lab results may include symbols, text, or qualitative values:

```text
< 0.05
> 1000
NON REACTIVE
Sample clotted
```

### 11.4 Add Auditability Early

Laboratory systems need traceability. Even if authentication is simple in the first version, design the database so validation, result entry, verification, and cancellation can later be tied to a user.

### 11.5 Avoid Hard-Coded Status Labels

Use enums for workflow status, but keep result interpretation values configurable where needed.

Work status can be controlled:

```text
pending, validated, verified, cancelled
```

Result values should remain dynamic:

```text
NON REACTIVE, REACTIVE, POSITIVE, NEGATIVE, DETECTED, NOT DETECTED
```

