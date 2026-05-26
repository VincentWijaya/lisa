# This file should ensure the existence of records required to run the application in every environment.
# Run with: bin/rails db:seed

puts "🌱 Seeding LISA database..."

# ─── Users ────────────────────────────────────────────────────────────────────

puts "👤 Creating users..."

admin_user = User.find_or_initialize_by(email: "admin@lisa.local")
admin_user.assign_attributes(name: "System Admin", password: "Password@123", active: true)
admin_user.save!
admin_user.add_role(:admin) unless admin_user.has_role?(:admin)

supervisor = User.find_or_initialize_by(email: "supervisor@lisa.local")
supervisor.assign_attributes(name: "Dr. Sarah Chen", password: "Password@123", active: true)
supervisor.save!
supervisor.add_role(:lab_supervisor) unless supervisor.has_role?(:lab_supervisor)

technician1 = User.find_or_initialize_by(email: "tech1@lisa.local")
technician1.assign_attributes(name: "Alex Rivera", password: "Password@123", active: true)
technician1.save!
technician1.add_role(:lab_technician) unless technician1.has_role?(:lab_technician)

technician2 = User.find_or_initialize_by(email: "tech2@lisa.local")
technician2.assign_attributes(name: "Maria Santos", password: "Password@123", active: true)
technician2.save!
technician2.add_role(:lab_technician) unless technician2.has_role?(:lab_technician)

doctor = User.find_or_initialize_by(email: "doctor@lisa.local")
doctor.assign_attributes(name: "Dr. James Okafor", password: "Password@123", active: true)
doctor.save!
doctor.add_role(:doctor) unless doctor.has_role?(:doctor)

puts "  ✅ #{User.count} users created"

# ─── Examinations ─────────────────────────────────────────────────────────────

puts "🔬 Creating examinations..."

examinations_data = [
  { name: "Glucose",                           code: "GLU",     specimen_type: "Blood", default_result_type: "numeric",     default_unit: "mg/dL", label_group: "CHEM"    },
  { name: "Creatinine",                         code: "CRE",     specimen_type: "Blood", default_result_type: "numeric",     default_unit: "mg/dL", label_group: "CHEM"    },
  { name: "Urea / BUN",                         code: "UR",      specimen_type: "Blood", default_result_type: "numeric",     default_unit: "mg/dL", label_group: "CHEM"    },
  { name: "Uric Acid",                          code: "UA",      specimen_type: "Blood", default_result_type: "numeric",     default_unit: "mg/dL", label_group: "CHEM"    },
  { name: "Total Cholesterol",                  code: "CHOL",    specimen_type: "Blood", default_result_type: "numeric",     default_unit: "mg/dL", label_group: "LIPID"   },
  { name: "Triglycerides",                      code: "TG",      specimen_type: "Blood", default_result_type: "numeric",     default_unit: "mg/dL", label_group: "LIPID"   },
  { name: "HDL Cholesterol",                    code: "HDL",     specimen_type: "Blood", default_result_type: "numeric",     default_unit: "mg/dL", label_group: "LIPID"   },
  { name: "LDL Cholesterol",                    code: "LDL",     specimen_type: "Blood", default_result_type: "numeric",     default_unit: "mg/dL", label_group: "LIPID"   },
  { name: "SGOT / AST",                         code: "SGOT",    specimen_type: "Blood", default_result_type: "numeric",     default_unit: "U/L",   label_group: "LFT"     },
  { name: "SGPT / ALT",                         code: "SGPT",    specimen_type: "Blood", default_result_type: "numeric",     default_unit: "U/L",   label_group: "LFT"     },
  { name: "Alkaline Phosphatase",               code: "ALP",     specimen_type: "Blood", default_result_type: "numeric",     default_unit: "U/L",   label_group: "LFT"     },
  { name: "Total Bilirubin",                    code: "TBIL",    specimen_type: "Blood", default_result_type: "numeric",     default_unit: "mg/dL", label_group: "LFT"     },
  { name: "Albumin",                            code: "ALB",     specimen_type: "Blood", default_result_type: "numeric",     default_unit: "g/dL",  label_group: "LFT"     },
  { name: "Complete Blood Count",               code: "CBC",     specimen_type: "Blood", default_result_type: "numeric",     default_unit: "cells/µL", label_group: nil    },
  { name: "Hemoglobin",                         code: "HGB",     specimen_type: "Blood", default_result_type: "numeric",     default_unit: "g/dL",  label_group: nil       },
  { name: "Urinalysis",                         code: "UA-URINE",specimen_type: "Urine", default_result_type: "qualitative", default_unit: nil,     label_group: nil       },
  { name: "HBsAg (Hepatitis B Surface Antigen)",code: "HBSAG",  specimen_type: "Blood", default_result_type: "qualitative", default_unit: nil,     label_group: "SERO"   },
  { name: "Anti-HCV",                           code: "HCV",     specimen_type: "Blood", default_result_type: "qualitative", default_unit: nil,     label_group: "SERO"   },
  { name: "HIV Rapid Test",                     code: "HIV",     specimen_type: "Blood", default_result_type: "qualitative", default_unit: nil,     label_group: "SERO"   },
  { name: "TSH",                                code: "TSH",     specimen_type: "Blood", default_result_type: "numeric",     default_unit: "mIU/L", label_group: "THYROID" },
  { name: "Free T4",                            code: "FT4",     specimen_type: "Blood", default_result_type: "numeric",     default_unit: "ng/dL", label_group: "THYROID" },
  { name: "Free T3",                            code: "FT3",     specimen_type: "Blood", default_result_type: "numeric",     default_unit: "pg/mL", label_group: "THYROID" },
]

examinations_data.each do |attrs|
  Examination.find_or_create_by!(code: attrs[:code]) do |e|
    e.name                = attrs[:name]
    e.specimen_type       = attrs[:specimen_type]
    e.default_result_type = attrs[:default_result_type]
    e.default_unit        = attrs[:default_unit]
    e.label_group         = attrs[:label_group]
    e.status              = "active"
  end
end

puts "  ✅ #{Examination.count} examinations created"

# ─── Reference Rules ──────────────────────────────────────────────────────────

puts "📏 Creating reference rules..."

def create_ref_rule(exam_code, name:, result_type:, low: nil, high: nil, unit: nil, normal: [], abnormal: [], critical: [], allowed: [], reference_value: nil, loinc: nil)
  exam = Examination.find_by!(code: exam_code)
  ReferenceRule.find_or_create_by!(examination_id: exam.id, name: name) do |r|
    r.result_type        = result_type
    r.numeric_low_value  = low
    r.numeric_high_value = high
    r.unit               = unit
    r.normal_values      = normal
    r.abnormal_values    = abnormal
    r.critical_values    = critical
    r.allowed_values     = allowed
    r.reference_value    = reference_value
    r.loinc_code         = loinc
    r.active             = true
  end
end

create_ref_rule "GLU",  name: "Adult Fasting Glucose",    result_type: "numeric", low: 70,   high: 100,  unit: "mg/dL", loinc: "2345-7"
create_ref_rule "CRE",  name: "Adult Male Creatinine",    result_type: "numeric", low: 0.74, high: 1.35, unit: "mg/dL", loinc: "2160-0"
create_ref_rule "CRE",  name: "Adult Female Creatinine",  result_type: "numeric", low: 0.59, high: 1.04, unit: "mg/dL", loinc: "2160-0"
create_ref_rule "UR",   name: "BUN Adult",                result_type: "numeric", low: 7,    high: 25,   unit: "mg/dL", loinc: "3094-0"
create_ref_rule "UA",   name: "Uric Acid Male",           result_type: "numeric", low: 3.4,  high: 7.0,  unit: "mg/dL", loinc: "3084-1"
create_ref_rule "UA",   name: "Uric Acid Female",         result_type: "numeric", low: 2.4,  high: 6.0,  unit: "mg/dL", loinc: "3084-1"
create_ref_rule "CHOL", name: "Total Cholesterol",        result_type: "numeric", low: 0,    high: 200,  unit: "mg/dL", loinc: "2093-3"
create_ref_rule "TG",   name: "Triglycerides Normal",     result_type: "numeric", low: 0,    high: 150,  unit: "mg/dL", loinc: "2571-8"
create_ref_rule "HDL",  name: "HDL Male",                 result_type: "numeric", low: 40,   high: 60,   unit: "mg/dL", loinc: "2085-9"
create_ref_rule "LDL",  name: "LDL Optimal",              result_type: "numeric", low: 0,    high: 100,  unit: "mg/dL", loinc: "13457-7"
create_ref_rule "SGOT", name: "AST Adult",                result_type: "numeric", low: 10,   high: 40,   unit: "U/L",   loinc: "1920-8"
create_ref_rule "SGPT", name: "ALT Adult",                result_type: "numeric", low: 7,    high: 56,   unit: "U/L",   loinc: "1742-6"
create_ref_rule "ALP",  name: "ALP Adult",                result_type: "numeric", low: 44,   high: 147,  unit: "U/L",   loinc: "6768-6"
create_ref_rule "TBIL", name: "Total Bilirubin",          result_type: "numeric", low: 0.1,  high: 1.2,  unit: "mg/dL", loinc: "1975-2"
create_ref_rule "ALB",  name: "Albumin Adult",            result_type: "numeric", low: 3.5,  high: 5.0,  unit: "g/dL",  loinc: "1751-7"
create_ref_rule "HGB",  name: "Hemoglobin Male",          result_type: "numeric", low: 13.5, high: 17.5, unit: "g/dL",  loinc: "718-7"
create_ref_rule "HGB",  name: "Hemoglobin Female",        result_type: "numeric", low: 12.0, high: 15.5, unit: "g/dL",  loinc: "718-7"
create_ref_rule "TSH",  name: "TSH Adult",                result_type: "numeric", low: 0.4,  high: 4.0,  unit: "mIU/L", loinc: "3016-3"
create_ref_rule "FT4",  name: "Free T4 Adult",            result_type: "numeric", low: 0.8,  high: 1.8,  unit: "ng/dL", loinc: "3024-7"
create_ref_rule "FT3",  name: "Free T3 Adult",            result_type: "numeric", low: 2.3,  high: 4.1,  unit: "pg/mL", loinc: "3051-0"

create_ref_rule "HBSAG", name: "HBsAg Rapid",   result_type: "qualitative",
  allowed: ["Reactive", "Non-Reactive", "Invalid"],
  normal: ["Non-Reactive"], abnormal: ["Reactive"], critical: ["Reactive"], loinc: "5196-1"

create_ref_rule "HCV", name: "Anti-HCV Rapid",   result_type: "qualitative",
  allowed: ["Reactive", "Non-Reactive", "Invalid"],
  normal: ["Non-Reactive"], abnormal: ["Reactive"], critical: ["Reactive"], loinc: "16128-1"

create_ref_rule "HIV", name: "HIV Rapid",         result_type: "qualitative",
  allowed: ["Reactive", "Non-Reactive", "Invalid"],
  normal: ["Non-Reactive"], abnormal: ["Reactive"], critical: ["Reactive"]

create_ref_rule "UA-URINE", name: "Urinalysis Routine", result_type: "qualitative",
  allowed: ["Normal", "Abnormal"],
  normal: ["Normal"], abnormal: ["Abnormal"]

puts "  ✅ #{ReferenceRule.count} reference rules created"

# ─── Sample Specimens & Works ─────────────────────────────────────────────────

puts "🧪 Creating sample specimens..."

if Specimen.count < 5
  chem_exam    = Examination.find_by!(code: "GLU")
  lipid_exam   = Examination.find_by!(code: "CHOL")
  thyroid_exam = Examination.find_by!(code: "TSH")
  sero_exam    = Examination.find_by!(code: "HBSAG")
  cbc_exam     = Examination.find_by!(code: "CBC")

  sample_patients = [
    { patient_id: "P-10001", patient_name: "Juan dela Cruz",  birth_date: "1985-04-12", gender: "male",   medical_record_id: "MR-2024-001", lab_id: "LAB-01", department: "Internal Medicine", examination_ids: [chem_exam.id, lipid_exam.id] },
    { patient_id: "P-10002", patient_name: "Maria Garcia",    birth_date: "1992-07-23", gender: "female", medical_record_id: "MR-2024-002", lab_id: "LAB-01", department: "OB-Gyne",          examination_ids: [thyroid_exam.id, cbc_exam.id] },
    { patient_id: "P-10003", patient_name: "Robert Tan",      birth_date: "1970-11-05", gender: "male",   medical_record_id: "MR-2024-003", lab_id: "LAB-01", department: "Cardiology",        examination_ids: [lipid_exam.id, sero_exam.id] },
    { patient_id: "P-10004", patient_name: "Luz Reyes",       birth_date: "1955-02-28", gender: "female", medical_record_id: nil,           lab_id: "LAB-02", department: "Geriatrics",        examination_ids: [chem_exam.id, thyroid_exam.id] },
    { patient_id: "P-10005", patient_name: "Paolo Mendez",    birth_date: "2001-09-18", gender: "male",   medical_record_id: "MR-2024-005", lab_id: "LAB-01", department: "ER",               examination_ids: [cbc_exam.id, sero_exam.id] },
  ]

  sample_patients.each do |data|
    result = Specimens::CreateService.call(
      patient_id:          data[:patient_id],
      patient_name:        data[:patient_name],
      birth_date:          data[:birth_date],
      gender:              data[:gender],
      medical_record_id:   data[:medical_record_id],
      lab_id:              data[:lab_id],
      department:          data[:department],
      collection_datetime: Time.current,
      examination_ids:     data[:examination_ids]
    )
    if result.failure?
      puts "  ⚠️  #{data[:patient_name]}: #{result.errors.join(', ')}"
    end
  end
end

puts "  ✅ #{Specimen.count} specimens, #{Work.count} works"

# ─── Sample Examination Results ───────────────────────────────────────────────

puts "📊 Creating sample examination results..."

if ExaminationResult.count < 5
  sample_result_data = [
    { examination_code: "GLU",  result_value: "95",           unit: "mg/dL", entered_by: "tech1@lisa.local" },
    { examination_code: "CRE",  result_value: "1.1",          unit: "mg/dL", entered_by: "tech1@lisa.local" },
    { examination_code: "CHOL", result_value: "185",          unit: "mg/dL", entered_by: "tech2@lisa.local" },
    { examination_code: "TSH",  result_value: "2.5",          unit: "mIU/L", entered_by: "tech2@lisa.local" },
    { examination_code: "HBSAG",result_value: "Non-Reactive", unit: nil,     entered_by: "tech1@lisa.local" },
    { examination_code: "HCV",  result_value: "Non-Reactive", unit: nil,     entered_by: "tech1@lisa.local" },
  ]

  sample_result_data.each do |data|
    work = Work.joins(:examination)
               .where(examinations: { code: data[:examination_code] })
               .where(status: %w[pending validated])
               .order(created_at: :desc)
               .first
    next unless work

    result = ExaminationResults::CreateService.call(
      work:   work,
      params: {
        result_value: data[:result_value],
        result_unit:  data[:unit],
        source:       "manual",
        entered_by:   data[:entered_by]
      }
    )

    puts "  ⚠️  #{data[:examination_code]}: #{result.errors.join(', ')}" if result.failure?
  end
end

puts "  ✅ #{ExaminationResult.count} examination results created"
puts ""
puts "✅ Seeding complete!"
puts ""
puts "📋 Login credentials (password: Password@123):"
puts "   admin@lisa.local       → admin"
puts "   supervisor@lisa.local  → lab_supervisor"
puts "   tech1@lisa.local       → lab_technician"
puts "   tech2@lisa.local       → lab_technician"
puts "   doctor@lisa.local      → doctor"
