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

# One examination per test panel / group.
# label_group → examinations sharing one barcode label.
# category    → report grouping (header in print report).
examinations_data = [
  # ── HEMATOLOGI ──
  { code: "HEMA-DL",    name: "Darah Lengkap",         category: "HEMATOLOGI",    label_group: "Darah Lengkap",   specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: nil      },
  { code: "LED",        name: "LED",                   category: "HEMATOLOGI",    label_group: nil,               specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: "mm/jam" },
  { code: "GOLDAR",     name: "Golongan Darah",        category: "HEMATOLOGI",    label_group: "Golongan Darah",  specimen_type: "Darah EDTA",  default_result_type: "qualitative", default_unit: nil      },
  # ── KIMIA KLINIK ──
  { code: "GDP",        name: "Glukosa Darah Puasa",   category: "KIMIA KLINIK",  label_group: nil,               specimen_type: "Darah Beku",  default_result_type: "numeric",     default_unit: "mg/dL"  },
  { code: "HBA1C",      name: "Panel HbA1C",           category: "KIMIA KLINIK",  label_group: "HbA1C",           specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: "%"      },
  { code: "LEMAK",      name: "Profil Lemak",          category: "KIMIA KLINIK",  label_group: "Profil Lemak",    specimen_type: "Darah Beku",  default_result_type: "numeric",     default_unit: "mg/dL"  },
  { code: "FUNGSI-H",   name: "Fungsi Hati",           category: "KIMIA KLINIK",  label_group: "Fungsi Hati",     specimen_type: "Darah Beku",  default_result_type: "numeric",     default_unit: "U/L"    },
  { code: "FUNGSI-G",   name: "Fungsi Ginjal",         category: "KIMIA KLINIK",  label_group: "Fungsi Ginjal",   specimen_type: "Darah Beku",  default_result_type: "numeric",     default_unit: "mg/dL"  },
  # ── IMUNOSEROLOGI ──
  { code: "HIV",        name: "Anti HIV",              category: "IMUNOSEROLOGI", label_group: nil,               specimen_type: "Darah Beku",  default_result_type: "qualitative", default_unit: nil      },
  { code: "VDRL",       name: "VDRL",                  category: "IMUNOSEROLOGI", label_group: nil,               specimen_type: "Darah Beku",  default_result_type: "qualitative", default_unit: nil      },
  # ── HEPATITIS ──
  { code: "ANTI-HBS",   name: "Anti HBs",              category: "HEPATITIS",     label_group: nil,               specimen_type: "Darah Beku",  default_result_type: "qualitative", default_unit: nil      },
  { code: "HBSAG",      name: "HBsAg",                 category: "HEPATITIS",     label_group: nil,               specimen_type: "Darah Beku",  default_result_type: "qualitative", default_unit: nil      },
  # ── URINALISIS ──
  { code: "URINE-L",    name: "Urine Lengkap",         category: "URINALISIS",    label_group: "Urine Lengkap",   specimen_type: "Urine Rutin", default_result_type: "qualitative", default_unit: nil      },
  { code: "URINE-S",    name: "Sedimen Urine",         category: "URINALISIS",    label_group: "Sedimen Urine",   specimen_type: "Urine Rutin", default_result_type: "qualitative", default_unit: nil      },
]

examinations_data.each do |attrs|
  exam = Examination.find_or_initialize_by(code: attrs[:code])
  exam.assign_attributes(
    name:                attrs[:name],
    category:            attrs[:category],
    label_group:         attrs[:label_group],
    specimen_type:       attrs[:specimen_type],
    default_result_type: attrs[:default_result_type],
    default_unit:        attrs[:default_unit],
    status:              "active"
  )
  exam.save!
end

puts "  ✅ #{Examination.count} examinations seeded"

# ─── Reference Rules ──────────────────────────────────────────────────────────

puts "📏 Creating reference rules..."

def upsert_ref_rule(exam_code, name:, result_type:, low: nil, high: nil, unit: nil,
                    normal: [], abnormal: [], critical: [], allowed: [],
                    reference_value: nil, loinc: nil)
  exam = Examination.find_by!(code: exam_code)
  rule = ReferenceRule.find_or_initialize_by(examination_id: exam.id, name: name)
  rule.assign_attributes(
    result_type:        result_type,
    numeric_low_value:  low,
    numeric_high_value: high,
    unit:               unit,
    normal_values:      normal,
    abnormal_values:    abnormal,
    critical_values:    critical,
    allowed_values:     allowed,
    reference_value:    reference_value,
    loinc_code:         loinc,
    active:             true
  )
  rule.save!
end

# ── Darah Lengkap (CBC) – each parameter is a separate reference rule ──
upsert_ref_rule "HEMA-DL", name: "Hemoglobin (Pria)",       result_type: "numeric",     low: 13.5, high: 18.0,  unit: "g/dL",      reference_value: "13.5 - 18.0",  loinc: "718-7"
upsert_ref_rule "HEMA-DL", name: "Hemoglobin (Wanita)",     result_type: "numeric",     low: 12.0, high: 16.0,  unit: "g/dL",      reference_value: "12.0 - 16.0",  loinc: "718-7"
upsert_ref_rule "HEMA-DL", name: "Hematokrit (Pria)",       result_type: "numeric",     low: 40,   high: 54,    unit: "%",         reference_value: "40 - 54",       loinc: "20570-8"
upsert_ref_rule "HEMA-DL", name: "Hematokrit (Wanita)",     result_type: "numeric",     low: 38,   high: 47,    unit: "%",         reference_value: "38 - 47",       loinc: "20570-8"
upsert_ref_rule "HEMA-DL", name: "Eritrosit (Pria)",        result_type: "numeric",     low: 4.20, high: 6.00,  unit: "10⁶/µL",   reference_value: "4.20 - 6.00",   loinc: "789-8"
upsert_ref_rule "HEMA-DL", name: "Eritrosit (Wanita)",      result_type: "numeric",     low: 3.80, high: 5.40,  unit: "10⁶/µL",   reference_value: "3.80 - 5.40",   loinc: "789-8"
upsert_ref_rule "HEMA-DL", name: "MCV",                     result_type: "numeric",     low: 80,   high: 100,   unit: "fL",        reference_value: "80 - 100",      loinc: "787-2"
upsert_ref_rule "HEMA-DL", name: "MCH",                     result_type: "numeric",     low: 26,   high: 34,    unit: "pg",        reference_value: "26 - 34",       loinc: "785-6"
upsert_ref_rule "HEMA-DL", name: "MCHC",                    result_type: "numeric",     low: 32,   high: 36,    unit: "g/dL",      reference_value: "32 - 36",       loinc: "786-4"
upsert_ref_rule "HEMA-DL", name: "RDW",                     result_type: "numeric",     low: 11.5, high: 14.5,  unit: "%",         reference_value: "11.5 - 14.5",   loinc: "788-0"
upsert_ref_rule "HEMA-DL", name: "Leukosit",                result_type: "numeric",     low: 3.6,  high: 10.6,  unit: "10³/µL",   reference_value: "3.6 - 10.6",    loinc: "6690-2"
upsert_ref_rule "HEMA-DL", name: "Basofil",                 result_type: "numeric",     low: 0,    high: 2,     unit: "%",         reference_value: "0 - 2",         loinc: "706-4"
upsert_ref_rule "HEMA-DL", name: "Eosinofil",               result_type: "numeric",     low: 1,    high: 3,     unit: "%",         reference_value: "1 - 3",         loinc: "713-8"
upsert_ref_rule "HEMA-DL", name: "Neutrofil",               result_type: "numeric",     low: 50,   high: 70,    unit: "%",         reference_value: "50 - 70",       loinc: "770-8"
upsert_ref_rule "HEMA-DL", name: "Limfosit",                result_type: "numeric",     low: 18,   high: 42,    unit: "%",         reference_value: "18 - 42",       loinc: "736-9"
upsert_ref_rule "HEMA-DL", name: "Monosit",                 result_type: "numeric",     low: 2,    high: 11,    unit: "%",         reference_value: "2 - 11",        loinc: "5905-5"
upsert_ref_rule "HEMA-DL", name: "Limfosit Absolut",        result_type: "numeric",     low: 1.5,  high: nil,   unit: "10³/µL",   reference_value: "> 1.5",         loinc: "731-0"
upsert_ref_rule "HEMA-DL", name: "Rasio Neutrofil/Limfosit",result_type: "text",                              unit: nil,         reference_value: "-"
upsert_ref_rule "HEMA-DL", name: "Trombosit",               result_type: "numeric",     low: 150,  high: 450,   unit: "10³/µL",   reference_value: "150 - 450",     loinc: "777-3"
upsert_ref_rule "HEMA-DL", name: "PDW",                     result_type: "numeric",     low: 9.1,  high: 15.3,  unit: "fL",        reference_value: "9.1 - 15.3"
upsert_ref_rule "HEMA-DL", name: "MPV",                     result_type: "numeric",     low: 8.7,  high: 11.8,  unit: "fL",        reference_value: "8.7 - 11.8"

# ── LED ──
upsert_ref_rule "LED", name: "LED (Pria)",   result_type: "numeric", low: 0, high: 15, unit: "mm/jam", reference_value: "0 - 15",  loinc: "4537-7"
upsert_ref_rule "LED", name: "LED (Wanita)", result_type: "numeric", low: 0, high: 20, unit: "mm/jam", reference_value: "0 - 20",  loinc: "4537-7"

# ── Golongan Darah ──
upsert_ref_rule "GOLDAR", name: "Golongan Darah", result_type: "qualitative",
  allowed: %w[A B AB O], normal: %w[A B AB O]
upsert_ref_rule "GOLDAR", name: "Rhesus", result_type: "qualitative",
  allowed: ["Positif (+)", "Negatif (-)"], normal: ["Positif (+)"], abnormal: ["Negatif (-)"]

# ── Glukosa Darah Puasa ──
upsert_ref_rule "GDP", name: "Glukosa Darah Puasa", result_type: "numeric",
  high: 100, unit: "mg/dL",
  reference_value: "Normal: < 100 | Gangguan Toleransi: 100–126 | Diabetes: > 126",
  loinc: "1558-6"

# ── Panel HbA1C ──
upsert_ref_rule "HBA1C", name: "HbA1C",                           result_type: "numeric", unit: "%",
  reference_value: "Diabetes: ≥ 6.5 | Prediabetes: 5.7–6.5 | Target Terapi: < 7.0", loinc: "4548-4"
upsert_ref_rule "HBA1C", name: "HbA1C (IFCC)",                    result_type: "numeric", unit: "mmol/mol",  reference_value: "-"
upsert_ref_rule "HBA1C", name: "eAG (Estimasi Glukosa Rata-rata)", result_type: "numeric", unit: "mg/dL",    reference_value: "-"

# ── Profil Lemak ──
upsert_ref_rule "LEMAK", name: "Kolesterol Total",   result_type: "numeric", high: 200, unit: "mg/dL",
  reference_value: "Diinginkan: < 200 | Batas Atas: 200–240 | Tinggi: ≥ 240", loinc: "2093-3"
upsert_ref_rule "LEMAK", name: "Kolesterol LDL",     result_type: "numeric", high: 100, unit: "mg/dL",
  reference_value: "Optimal: < 100 | Hampir Optimal: 100–130 | Batas Atas: 130–160 | Tinggi: 160–190 | Sangat Tinggi: ≥ 190", loinc: "13457-7"
upsert_ref_rule "LEMAK", name: "Kolesterol HDL",     result_type: "numeric", low: 60,   unit: "mg/dL",
  reference_value: "Optimal: ≥ 60 | Batas: 40–59 | Risiko Tinggi: < 40", loinc: "2085-9"
upsert_ref_rule "LEMAK", name: "Trigliserida",       result_type: "numeric", high: 150, unit: "mg/dL",
  reference_value: "Normal: < 150 | Batas Atas: 150–200 | Tinggi: 200–500 | Sangat Tinggi: ≥ 500", loinc: "2571-8"
upsert_ref_rule "LEMAK", name: "Kolesterol Non-HDL", result_type: "numeric", high: 130, unit: "mg/dL",
  reference_value: "Optimal: < 130 | Hampir Optimal: 130–159 | Batas Atas: 160–189 | Tinggi: 190–219 | Sangat Tinggi: ≥ 220", loinc: "43396-1"

# ── Fungsi Hati ──
upsert_ref_rule "FUNGSI-H", name: "SGOT (AST)",             result_type: "numeric", low: 10, high: 40,  unit: "U/L",   reference_value: "10 - 40",  loinc: "1920-8"
upsert_ref_rule "FUNGSI-H", name: "SGPT (ALT)",             result_type: "numeric", low: 7,  high: 56,  unit: "U/L",   reference_value: "7 - 56",   loinc: "1742-6"
upsert_ref_rule "FUNGSI-H", name: "Alkali Fosfatase (ALP)", result_type: "numeric", low: 44, high: 147, unit: "U/L",   reference_value: "44 - 147", loinc: "6768-6"
upsert_ref_rule "FUNGSI-H", name: "Bilirubin Total",        result_type: "numeric", low: 0.1,high: 1.2, unit: "mg/dL", reference_value: "0.1 - 1.2",loinc: "1975-2"
upsert_ref_rule "FUNGSI-H", name: "Albumin",                result_type: "numeric", low: 3.5,high: 5.0, unit: "g/dL",  reference_value: "3.5 - 5.0",loinc: "1751-7"
upsert_ref_rule "FUNGSI-H", name: "Gamma GT",               result_type: "numeric", low: 8,  high: 61,  unit: "U/L",   reference_value: "8 - 61",   loinc: "2324-2"

# ── Fungsi Ginjal ──
upsert_ref_rule "FUNGSI-G", name: "Ureum",               result_type: "numeric", low: 15, high: 45,  unit: "mg/dL", reference_value: "15 - 45",    loinc: "3094-0"
upsert_ref_rule "FUNGSI-G", name: "Kreatinin (Pria)",    result_type: "numeric", low: 0.7,high: 1.2, unit: "mg/dL", reference_value: "0.7 - 1.2",  loinc: "2160-0"
upsert_ref_rule "FUNGSI-G", name: "Kreatinin (Wanita)",  result_type: "numeric", low: 0.5,high: 1.0, unit: "mg/dL", reference_value: "0.5 - 1.0",  loinc: "2160-0"
upsert_ref_rule "FUNGSI-G", name: "Asam Urat (Pria)",    result_type: "numeric", low: 3.4,high: 7.0, unit: "mg/dL", reference_value: "3.4 - 7.0",  loinc: "3084-1"
upsert_ref_rule "FUNGSI-G", name: "Asam Urat (Wanita)",  result_type: "numeric", low: 2.4,high: 6.0, unit: "mg/dL", reference_value: "2.4 - 6.0",  loinc: "3084-1"

# ── Anti HIV ──
upsert_ref_rule "HIV", name: "Anti HIV", result_type: "qualitative",
  allowed: ["Reaktif", "Non Reaktif"], normal: ["Non Reaktif"],
  abnormal: ["Reaktif"], critical: ["Reaktif"]

# ── VDRL ──
upsert_ref_rule "VDRL", name: "VDRL", result_type: "qualitative",
  allowed: ["Reaktif", "Non Reaktif"], normal: ["Non Reaktif"], abnormal: ["Reaktif"]

# ── Anti HBs ──
upsert_ref_rule "ANTI-HBS", name: "Anti HBs (Kualitatif)", result_type: "qualitative",
  allowed: %w[Positif Negatif], normal: %w[Negatif], abnormal: %w[Positif]

# ── HBsAg ──
upsert_ref_rule "HBSAG", name: "HBsAg (Kualitatif)", result_type: "qualitative",
  allowed: ["Reaktif", "Non Reaktif"], normal: ["Non Reaktif"],
  abnormal: ["Reaktif"], critical: ["Reaktif"], loinc: "5196-1"

# ── Urine Lengkap ──
KUNING_NORMAL = ["Kuning Muda", "Kuning", "Kuning Tua"].freeze
upsert_ref_rule "URINE-L", name: "Warna",             result_type: "qualitative",
  allowed: KUNING_NORMAL + ["Merah", "Coklat", "Keruh"], normal: KUNING_NORMAL, abnormal: ["Merah", "Coklat"]
upsert_ref_rule "URINE-L", name: "Kejernihan",         result_type: "qualitative",
  allowed: %w[Jernih Keruh], normal: %w[Jernih], abnormal: %w[Keruh]
upsert_ref_rule "URINE-L", name: "Berat Jenis",        result_type: "numeric", low: 1.003, high: 1.030, reference_value: "1.003 - 1.030"
upsert_ref_rule "URINE-L", name: "pH",                 result_type: "numeric", low: 4.5,   high: 8.0,   reference_value: "4.5 - 8"
upsert_ref_rule "URINE-L", name: "Protein",            result_type: "qualitative",
  allowed: %w[Negatif Positif +1 +2 +3], normal: %w[Negatif], abnormal: %w[Positif +1 +2 +3]
upsert_ref_rule "URINE-L", name: "Glukosa",            result_type: "qualitative",
  allowed: %w[Negatif Positif +1 +2 +3], normal: %w[Negatif], abnormal: %w[Positif +1 +2 +3]
upsert_ref_rule "URINE-L", name: "Keton",              result_type: "qualitative",
  allowed: %w[Negatif Positif +1 +2 +3], normal: %w[Negatif], abnormal: %w[Positif +1 +2 +3]
upsert_ref_rule "URINE-L", name: "Bilirubin",          result_type: "qualitative",
  allowed: %w[Negatif Positif +1 +2 +3], normal: %w[Negatif], abnormal: %w[Positif +1 +2 +3]
upsert_ref_rule "URINE-L", name: "Darah",              result_type: "qualitative",
  allowed: %w[Negatif Positif +1 +2 +3], normal: %w[Negatif], abnormal: %w[Positif +1 +2 +3]
upsert_ref_rule "URINE-L", name: "Nitrit",             result_type: "qualitative",
  allowed: %w[Negatif Positif], normal: %w[Negatif], abnormal: %w[Positif]
upsert_ref_rule "URINE-L", name: "Urobilinogen",       result_type: "qualitative",
  allowed: %w[<1 Normal Positif], normal: %w[<1 Normal], reference_value: "< 1 mg/dL"
upsert_ref_rule "URINE-L", name: "Esterase Lekosit",  result_type: "qualitative",
  allowed: %w[Negatif Positif +1 +2 +3], normal: %w[Negatif], abnormal: %w[Positif +1 +2 +3]

# ── Sedimen Urine ──
upsert_ref_rule "URINE-S", name: "Lekosit",  result_type: "numeric",     high: 11, unit: "/uL", reference_value: "< 11"
upsert_ref_rule "URINE-S", name: "Eritrosit",result_type: "numeric",     high: 16, unit: "/uL", reference_value: "< 16"
upsert_ref_rule "URINE-S", name: "Epitel",   result_type: "qualitative", allowed: %w[Negatif Positif],                normal: %w[Positif Negatif]
upsert_ref_rule "URINE-S", name: "Silinder", result_type: "qualitative", allowed: %w[Negatif Positif], normal: %w[Negatif], abnormal: %w[Positif]
upsert_ref_rule "URINE-S", name: "Kristal",  result_type: "qualitative", allowed: %w[Negatif Positif], normal: %w[Negatif], abnormal: %w[Positif]
upsert_ref_rule "URINE-S", name: "Jamur",    result_type: "qualitative", allowed: %w[Negatif Positif], normal: %w[Negatif], abnormal: %w[Positif]
upsert_ref_rule "URINE-S", name: "Bakteri",  result_type: "qualitative", allowed: %w[Negatif Positif], normal: %w[Negatif], abnormal: %w[Positif]

puts "  ✅ #{ReferenceRule.count} reference rules seeded"

# ─── Sample Specimens & Works ─────────────────────────────────────────────────

puts "🧪 Creating sample specimens..."

if Specimen.count < 5
  darah_lengkap = Examination.find_by!(code: "HEMA-DL")
  profil_lemak  = Examination.find_by!(code: "LEMAK")
  hba1c         = Examination.find_by!(code: "HBA1C")
  anti_hiv      = Examination.find_by!(code: "HIV")
  urine_l       = Examination.find_by!(code: "URINE-L")
  fungsi_ginjal = Examination.find_by!(code: "FUNGSI-G")

  sample_patients = [
    {
      patient_id: "P-10001", patient_name: "Budi Santoso",      birth_date: "1985-04-12",
      gender: "Laki-laki",   medical_record_id: "RM-2024-001",  lab_id: "LAB-01",
      department: "Penyakit Dalam", referring_doctor: "dr. Andi Kusuma, Sp.PD",
      examination_ids: [darah_lengkap.id, profil_lemak.id]
    },
    {
      patient_id: "P-10002", patient_name: "Siti Rahayu",       birth_date: "1992-07-23",
      gender: "Perempuan",   medical_record_id: "RM-2024-002",  lab_id: "LAB-01",
      department: "Kebidanan", referring_doctor: "dr. Dewi Lestari, Sp.OG",
      examination_ids: [darah_lengkap.id, hba1c.id]
    },
    {
      patient_id: "P-10003", patient_name: "Ahmad Wijaya",      birth_date: "1970-11-05",
      gender: "Laki-laki",   medical_record_id: "RM-2024-003",  lab_id: "LAB-01",
      department: "Kardiologi", referring_doctor: "dr. Hendra Gunawan, Sp.JP",
      examination_ids: [profil_lemak.id, hba1c.id, anti_hiv.id]
    },
    {
      patient_id: "P-10004", patient_name: "Dewi Susanti",      birth_date: "1955-02-28",
      gender: "Perempuan",   medical_record_id: nil,             lab_id: "LAB-02",
      department: "Geriatri",
      examination_ids: [fungsi_ginjal.id, darah_lengkap.id]
    },
    {
      patient_id: "P-10005", patient_name: "Rizki Pratama",     birth_date: "2001-09-18",
      gender: "Laki-laki",   medical_record_id: "RM-2024-005",  lab_id: "LAB-01",
      department: "IGD",
      examination_ids: [darah_lengkap.id, urine_l.id, anti_hiv.id]
    },
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
      referring_doctor:    data[:referring_doctor],
      collection_datetime: Time.current,
      examination_ids:     data[:examination_ids]
    )
    puts "  ⚠️  #{data[:patient_name]}: #{result.errors.join(', ')}" if result.failure?
  end
end

puts "  ✅ #{Specimen.count} specimens, #{Work.count} works"

# ─── Sample Examination Results ───────────────────────────────────────────────

puts "📊 Creating sample examination results..."

if ExaminationResult.count < 5
  tech1 = User.find_by!(email: "tech1@lisa.local")

  # Map: exam code → list of {ref_rule_name, result_value}
  sample_results = {
    "HEMA-DL" => [
      { ref: "Hemoglobin (Pria)",        val: "15.3",       unit: "g/dL"    },
      { ref: "Hematokrit (Pria)",        val: "45.5",       unit: "%"       },
      { ref: "Eritrosit (Pria)",         val: "5.58",       unit: "10⁶/µL" },
      { ref: "MCV",                      val: "82",         unit: "fL"      },
      { ref: "MCH",                      val: "27",         unit: "pg"      },
      { ref: "MCHC",                     val: "34",         unit: "g/dL"    },
      { ref: "RDW",                      val: "11.8",       unit: "%"       },
      { ref: "Leukosit",                 val: "7.6",        unit: "10³/µL" },
      { ref: "Basofil",                  val: "0.5",        unit: "%"       },
      { ref: "Eosinofil",                val: "7.0",        unit: "%"       },
      { ref: "Neutrofil",                val: "49.5",       unit: "%"       },
      { ref: "Limfosit",                 val: "34.6",       unit: "%"       },
      { ref: "Monosit",                  val: "8.4",        unit: "%"       },
      { ref: "Limfosit Absolut",         val: "2.63",       unit: "10³/µL" },
      { ref: "Rasio Neutrofil/Limfosit", val: "1.43",       unit: nil       },
      { ref: "Trombosit",                val: "333",        unit: "10³/µL" },
      { ref: "PDW",                      val: "10.6",       unit: "fL"      },
      { ref: "MPV",                      val: "9.6",        unit: "fL"      },
    ],
    "LEMAK" => [
      { ref: "Kolesterol Total",   val: "211", unit: "mg/dL" },
      { ref: "Kolesterol LDL",     val: "155", unit: "mg/dL" },
      { ref: "Kolesterol HDL",     val: "38",  unit: "mg/dL" },
      { ref: "Trigliserida",       val: "91",  unit: "mg/dL" },
      { ref: "Kolesterol Non-HDL", val: "173", unit: "mg/dL" },
    ],
    "HBA1C" => [
      { ref: "HbA1C",                            val: "5.4",  unit: "%" },
      { ref: "HbA1C (IFCC)",                     val: "35.5", unit: "mmol/mol" },
      { ref: "eAG (Estimasi Glukosa Rata-rata)",  val: "108", unit: "mg/dL" },
    ],
    "HIV" => [
      { ref: "Anti HIV", val: "Non Reaktif", unit: nil },
    ],
  }

  sample_results.each do |exam_code, rows|
    work = Work.joins(:examination).where(examinations: { code: exam_code })
               .where(status: %w[pending validated]).order(created_at: :desc).first
    next unless work

    exam    = Examination.find_by!(code: exam_code)

    rows.each do |row|
      ref_rule = ReferenceRule.find_by(examination: exam, name: row[:ref])

      ExaminationResult.find_or_create_by!(work: work, reference_rule: ref_rule) do |er|
        er.result_value = row[:val]
        er.result_unit  = row[:unit]
        er.source       = "manual"
        er.entered_by   = tech1.id
      end
    end
  end
end

puts "  ✅ #{ExaminationResult.count} examination results seeded"
puts ""
puts "✅ Seeding selesai!"
puts ""
puts "📋 Kredensial login (password: Password@123):"
puts "   admin@lisa.local       → admin"
puts "   supervisor@lisa.local  → lab_supervisor"
puts "   tech1@lisa.local       → lab_technician"
puts "   tech2@lisa.local       → lab_technician"
puts "   doctor@lisa.local      → doctor"
