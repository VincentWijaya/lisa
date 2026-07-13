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

# One examination per analyzer row/test.
# label_group → examinations sharing one barcode label.
# category    → report grouping (header in print report).
darah_lengkap_codes = %w[RDW-CV RDW-SD MONO LYMPH SEG BAND EOS BASO MCHC MCH MCV RBC PLT HCT WBC HGB BAS# NEU# EOS# MON# LYM# MPV PDW PCT PLCC PLCR].freeze
elektrolit_codes = %w[CL K NA].freeze
fungsi_ginjal_codes = %w[CRE UR].freeze

examinations_data = [
  # ── HEMATOLOGI / DARAH LENGKAP (LOINC aligned: 718-7, 4544-3, 789-8, 6690-2, 777-3, 787-2, 785-6, 786-4, 788-0, 21232-4, 4537-7, 711-2) ──
  { code: "RDW-CV",     name: "RDW-CV",                category: "HEMATOLOGI",    label_group: "Darah Lengkap",   specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: "%"      },
  { code: "RDW-SD",     name: "RDW-SD",                category: "HEMATOLOGI",    label_group: "Darah Lengkap",   specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: "fL"     },
  { code: "MONO",       name: "Monosit",               category: "HEMATOLOGI",    label_group: "Darah Lengkap",   specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: "%"      },
  { code: "LYMPH",      name: "Limfosit",              category: "HEMATOLOGI",    label_group: "Darah Lengkap",   specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: "%"      },
  { code: "SEG",        name: "Segmen",                category: "HEMATOLOGI",    label_group: "Darah Lengkap",   specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: "%"      },
  { code: "BAND",       name: "Batang",                category: "HEMATOLOGI",    label_group: "Darah Lengkap",   specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: "%"      },
  { code: "EOS",        name: "Eosinofil",             category: "HEMATOLOGI",    label_group: "Darah Lengkap",   specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: "%"      },
  { code: "BASO",       name: "Basofil",               category: "HEMATOLOGI",    label_group: "Darah Lengkap",   specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: "%"      },
  { code: "MCHC",       name: "MCHC",                  category: "HEMATOLOGI",    label_group: "Darah Lengkap",   specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: "g/dL"   },
  { code: "MCH",        name: "MCH",                   category: "HEMATOLOGI",    label_group: "Darah Lengkap",   specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: "pg"     },
  { code: "MCV",        name: "MCV",                   category: "HEMATOLOGI",    label_group: "Darah Lengkap",   specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: "fL"     },
  { code: "RBC",        name: "ERITROSIT",             category: "HEMATOLOGI",    label_group: "Darah Lengkap",   specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: "10⁶/µL" },
  { code: "PLT",        name: "Trombosit",             category: "HEMATOLOGI",    label_group: "Darah Lengkap",   specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: "10³/µL" },
  { code: "HCT",        name: "Hematokrit",            category: "HEMATOLOGI",    label_group: "Darah Lengkap",   specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: "%"      },
  { code: "WBC",        name: "Lekosit",               category: "HEMATOLOGI",    label_group: "Darah Lengkap",   specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: "10³/µL" },
  { code: "HGB",        name: "Hemoglobin",            category: "HEMATOLOGI",    label_group: "Darah Lengkap",   specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: "g/dL"   },
  { code: "BAS#",       name: "Basofil Absolut",       category: "HEMATOLOGI",    label_group: "Darah Lengkap",   specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: "10³/µL" },
  { code: "NEU#",       name: "Neutrofil Absolut",     category: "HEMATOLOGI",    label_group: "Darah Lengkap",   specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: "10³/µL" },
  { code: "EOS#",       name: "Eosinofil Absolut",     category: "HEMATOLOGI",    label_group: "Darah Lengkap",   specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: "10³/µL" },
  { code: "MON#",       name: "Monosit Absolut",       category: "HEMATOLOGI",    label_group: "Darah Lengkap",   specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: "10³/µL" },
  { code: "MPV",        name: "MPV",                   category: "HEMATOLOGI",    label_group: "Darah Lengkap",   specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: "fL"     },
  { code: "PDW",        name: "PDW",                   category: "HEMATOLOGI",    label_group: "Darah Lengkap",   specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: nil      },
  { code: "PCT",        name: "PCT",                   category: "HEMATOLOGI",    label_group: "Darah Lengkap",   specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: "mL/L"   },
  { code: "PLCC",       name: "PLCC",                  category: "HEMATOLOGI",    label_group: "Darah Lengkap",   specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: "10⁹/L"  },
  { code: "PLCR",       name: "PLCR",                  category: "HEMATOLOGI",    label_group: "Darah Lengkap",   specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: "%"      },
  { code: "LED",        name: "LED",                   category: "HEMATOLOGI",    label_group: nil,               specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: "mm/jam" },
  { code: "DIFF",       name: "Hitung Jenis (DIFF)",   category: "HEMATOLOGI",    label_group: "Darah Lengkap",   specimen_type: "Darah EDTA",  default_result_type: "qualitative", default_unit: nil      },
  { code: "GOLDAR",     name: "Golongan Darah",        category: "HEMATOLOGI",    label_group: "Golongan Darah",  specimen_type: "Darah EDTA",  default_result_type: "qualitative", default_unit: nil      },

  # ── HEMATOLOGI / Tambahan (LOINC: 26515-7, 883-9, 10331-7, 17849-1, 1250-7, 1007-4, 890-4, 2132-9, 49019-1, 30522-7) ──
  { code: "PHLEBO",     name: "Phlebotomi",            category: "HEMATOLOGI",    label_group: nil,               specimen_type: "Darah EDTA",  default_result_type: "qualitative", default_unit: nil      },
  { code: "RETIC",      name: "Retikulosit",           category: "HEMATOLOGI",    label_group: nil,               specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: "%"      },
  { code: "CROSSMATCH", name: "Cross Match",           category: "HEMATOLOGI",    label_group: nil,               specimen_type: "Darah EDTA",  default_result_type: "qualitative", default_unit: nil      },
  { code: "COOMBS-D",   name: "Coombs Test Direk",     category: "HEMATOLOGI",    label_group: nil,               specimen_type: "Darah EDTA",  default_result_type: "qualitative", default_unit: nil      },
  { code: "COOMBS-I",   name: "Coombs Test Indirek",   category: "HEMATOLOGI",    label_group: nil,               specimen_type: "Darah Beku",  default_result_type: "qualitative", default_unit: nil      },
  { code: "VITB12",     name: "Vitamin B12",           category: "HEMATOLOGI",    label_group: nil,               specimen_type: "Darah Beku",  default_result_type: "numeric",     default_unit: "pg/mL"  },
  { code: "HAMSTEST",   name: "Hams Test",             category: "HEMATOLOGI",    label_group: nil,               specimen_type: "Darah EDTA",  default_result_type: "qualitative", default_unit: nil      },
  { code: "ITRATIO",    name: "IT Ratio",              category: "HEMATOLOGI",    label_group: nil,               specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: "Rasio"  },
  # ── KIMIA KLINIK ──
  { code: "CL",         name: "Chloride (Cl)",         category: "KIMIA KLINIK",  label_group: "Elektrolit",      specimen_type: "Darah Beku",  default_result_type: "numeric",     default_unit: "mmol/L" },
  { code: "K",          name: "Kalium (K)",            category: "KIMIA KLINIK",  label_group: "Elektrolit",      specimen_type: "Darah Beku",  default_result_type: "numeric",     default_unit: "mmol/L" },
  { code: "NA",         name: "Natrium (Na)",          category: "KIMIA KLINIK",  label_group: "Elektrolit",      specimen_type: "Darah Beku",  default_result_type: "numeric",     default_unit: "mmol/L" },
  { code: "CRE",        name: "CREATININE",            category: "KIMIA KLINIK",  label_group: "Fungsi Ginjal",   specimen_type: "Darah Beku",  default_result_type: "numeric",     default_unit: "mg/dL"  },
  { code: "UR",         name: "UREUM",                 category: "KIMIA KLINIK",  label_group: "Fungsi Ginjal",   specimen_type: "Darah Beku",  default_result_type: "numeric",     default_unit: "mg/dL"  },
  { code: "GDS",        name: "GULA DARAH SEWAKTU",    category: "KIMIA KLINIK",  label_group: nil,               specimen_type: "Darah Beku",  default_result_type: "numeric",     default_unit: "mg/dL"  },
  { code: "HBA1C",      name: "Panel HbA1C",           category: "KIMIA KLINIK",  label_group: "HbA1C",           specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: "%"      },
  { code: "LEMAK",      name: "Profil Lemak",          category: "KIMIA KLINIK",  label_group: "Profil Lemak",    specimen_type: "Darah Beku",  default_result_type: "numeric",     default_unit: "mg/dL"  },
  { code: "FUNGSI-H",   name: "Fungsi Hati",           category: "KIMIA KLINIK",  label_group: "Fungsi Hati",     specimen_type: "Darah Beku",  default_result_type: "numeric",     default_unit: "U/L"    },
  # ── KIMIA KLINIK / Tambahan (LOINC: 2885-2, 1751-7, 2336-6, 1798-8, 3040-3, 2532-0) ──
  { code: "TP",         name: "Total Protein",         category: "KIMIA KLINIK",  label_group: nil,               specimen_type: "Darah Beku",  default_result_type: "numeric",     default_unit: "g/dL"   },
  { code: "ALB",        name: "Albumin",               category: "KIMIA KLINIK",  label_group: nil,               specimen_type: "Darah Beku",  default_result_type: "numeric",     default_unit: "g/dL"   },
  { code: "AMY",        name: "Amilase Serum",         category: "KIMIA KLINIK",  label_group: nil,               specimen_type: "Darah Beku",  default_result_type: "numeric",     default_unit: "U/L"    },
  { code: "LIP",        name: "Lipase Serum",          category: "KIMIA KLINIK",  label_group: nil,               specimen_type: "Darah Beku",  default_result_type: "numeric",     default_unit: "U/L"    },
  { code: "LDH",        name: "Laktat Dehidrogenase",  category: "KIMIA KLINIK",  label_group: nil,               specimen_type: "Darah Beku",  default_result_type: "numeric",     default_unit: "U/L"    },
  # ── IMUNOSEROLOGI ──
  { code: "HIV",        name: "Anti HIV",              category: "IMUNOSEROLOGI", label_group: nil,               specimen_type: "Darah Beku",  default_result_type: "qualitative", default_unit: nil      },
  { code: "VDRL",       name: "VDRL",                  category: "IMUNOSEROLOGI", label_group: nil,               specimen_type: "Darah Beku",  default_result_type: "qualitative", default_unit: nil      },
  # ── HEPATITIS ──
  { code: "ANTI-HBS",   name: "Anti HBs",              category: "HEPATITIS",     label_group: nil,               specimen_type: "Darah Beku",  default_result_type: "qualitative", default_unit: nil      },
  { code: "HBSAG",      name: "HBsAg",                 category: "HEPATITIS",     label_group: nil,               specimen_type: "Darah Beku",  default_result_type: "qualitative", default_unit: nil      },
  # ── URINALISIS ──
  { code: "URINE-L",    name: "Urine Lengkap",         category: "URINALISIS",    label_group: "Urine Lengkap",   specimen_type: "Urine Rutin", default_result_type: "qualitative", default_unit: nil      },
  { code: "URINE-S",    name: "Sedimen Urine",         category: "URINALISIS",    label_group: "Sedimen Urine",   specimen_type: "Urine Rutin", default_result_type: "qualitative", default_unit: nil      },
  # ── FAECES (LOINC: 9397-5, 48021-0, 43398-7, 14725-6, 19005-8, 6762-9, 10701-1, 10703-7, 29771-3) ──
  { code: "FAECES",     name: "Faeces Lengkap",        category: "FAECES",        label_group: "Faeces Lengkap",  specimen_type: "Faeces",      default_result_type: "qualitative", default_unit: nil      },
  # ── MIKROBIOLOGI (LOINC: 664-3, 11545-1, 632-4, 625-8) ──
  { code: "GRAM",       name: "Pewarnaan Gram",        category: "MIKROBIOLOGI",  label_group: nil,               specimen_type: "Swab",        default_result_type: "qualitative", default_unit: nil      },
  { code: "BTA",        name: "Pewarnaan BTA",         category: "MIKROBIOLOGI",  label_group: nil,               specimen_type: "Sputum",      default_result_type: "qualitative", default_unit: nil      },
  { code: "KULTUR",     name: "Kultur & Sensitivitas", category: "MIKROBIOLOGI",  label_group: nil,               specimen_type: "Swab",        default_result_type: "text",        default_unit: nil      },
  { code: "KOH",        name: "Pewarnaan Jamur (KOH)", category: "MIKROBIOLOGI",  label_group: nil,               specimen_type: "Swab",        default_result_type: "qualitative", default_unit: nil      },
  # ── PATOLOGI ANATOMI (LOINC: 49015-9, 33717-0, 44835-7, 10524-7) ──
  { code: "HPA",        name: "Histopatologi (Biopsi)",  category: "PATOLOGI ANATOMI", label_group: nil,          specimen_type: "Jaringan",    default_result_type: "text",        default_unit: nil      },
  { code: "SITOLOGI",   name: "Sitologi Non-Ginekologi", category: "PATOLOGI ANATOMI", label_group: nil,          specimen_type: "Sitologi",    default_result_type: "text",        default_unit: nil      },
  { code: "FNAB",       name: "Fine Needle Aspiration",  category: "PATOLOGI ANATOMI", label_group: nil,          specimen_type: "Aspirat",     default_result_type: "text",        default_unit: nil      },
  { code: "PAP",        name: "Pap Smear",               category: "PATOLOGI ANATOMI", label_group: nil,          specimen_type: "Sekret Serviks", default_result_type: "text",     default_unit: nil      },

  # ── Computed source examinations (referenced by formula rules below) ──
  { code: "LYM#",       name: "Limfosit Absolut",      category: "HEMATOLOGI",    label_group: "Darah Lengkap",   specimen_type: "Darah EDTA",  default_result_type: "numeric",     default_unit: "10³/µL" },
  { code: "CHOL",       name: "Cholesterol Total",     category: "KIMIA KLINIK",  label_group: "Profil Lemak",    specimen_type: "Darah Beku",  default_result_type: "numeric",     default_unit: "mg/dL"  },
  { code: "TG",         name: "Trigliserida",          category: "KIMIA KLINIK",  label_group: "Profil Lemak",    specimen_type: "Darah Beku",  default_result_type: "numeric",     default_unit: "mg/dL"  },
  { code: "HDL",        name: "HDL Cholesterol",       category: "KIMIA KLINIK",  label_group: "Profil Lemak",    specimen_type: "Darah Beku",  default_result_type: "numeric",     default_unit: "mg/dL"  },
  { code: "TOT_BIL",    name: "Bilirubin Total",       category: "KIMIA KLINIK",  label_group: "Fungsi Hati",     specimen_type: "Darah Beku",  default_result_type: "numeric",     default_unit: "mg/dL"  },
  { code: "DIREK_BIL",  name: "Bilirubin Direk",       category: "KIMIA KLINIK",  label_group: "Fungsi Hati",     specimen_type: "Darah Beku",  default_result_type: "numeric",     default_unit: "mg/dL"  },
  { code: "TP",         name: "Total Protein",         category: "KIMIA KLINIK",  label_group: "Fungsi Hati",     specimen_type: "Darah Beku",  default_result_type: "numeric",     default_unit: "g/dL"   },
  { code: "ALB",        name: "Albumin",               category: "KIMIA KLINIK",  label_group: "Fungsi Hati",     specimen_type: "Darah Beku",  default_result_type: "numeric",     default_unit: "g/dL"   },

  # ── Computed examinations (values produced by formula rules) ──
  { code: "NLR",        name: "Neutrophil-Lymphocyte Ratio",  category: "HEMATOLOGI",    label_group: nil, specimen_type: "Darah EDTA", default_result_type: "numeric", default_unit: nil   },
  { code: "LDL-CALC",   name: "LDL Cholesterol (Calculated)", category: "KIMIA KLINIK",  label_group: nil, specimen_type: "Darah Beku",  default_result_type: "numeric", default_unit: "mg/dL" },
  { code: "CHOL-RATIO", name: "Cholesterol Ratio",            category: "KIMIA KLINIK",  label_group: nil, specimen_type: "Darah Beku",  default_result_type: "numeric", default_unit: nil   },
  { code: "INDIREK",    name: "Bilirubin Indirek",            category: "KIMIA KLINIK",  label_group: nil, specimen_type: "Darah Beku",  default_result_type: "numeric", default_unit: "mg/dL" },
  { code: "GLOB",       name: "Globulin",                     category: "KIMIA KLINIK",  label_group: nil, specimen_type: "Darah Beku",  default_result_type: "numeric", default_unit: "g/dL"  },
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

# Retire previous panel-style seed rows now represented by screenshot tests.
Examination.where(code: %w[HEMA-DL FUNGSI-G GDP]).find_each do |exam|
  exam.update!(status: "inactive")
end

puts "  ✅ #{Examination.count} examinations seeded"

# ─── Reference Rules ──────────────────────────────────────────────────────────

puts "📏 Creating reference rules..."

def upsert_ref_rule(exam_code, name:, result_type:, low: nil, high: nil, unit: nil,
                    normal: [], abnormal: [], critical: [], allowed: [],
                    reference_value: nil, loinc: nil, previous_names: [], gender: nil,
                    formula_expression: nil, formula_inputs: nil)
  exam = Examination.find_by!(code: exam_code)
  rule = ReferenceRule.find_by(examination_id: exam.id, name: name)
  rule ||= ReferenceRule.where(examination_id: exam.id, name: previous_names).order(:id).first if previous_names.any?
  rule ||= ReferenceRule.new(examination: exam)
  rule.assign_attributes(
    name:               name,
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
    gender:             gender,
    formula_expression: formula_expression,
    formula_inputs:     formula_inputs || [],
    active:             true
  )
  rule.save!
end

# ── Darah Lengkap (CBC) – names follow the screenshot order, ranges per LOINC Kamus ──
upsert_ref_rule "RDW-CV", name: "Darah Lengkap (Panel)",  result_type: "qualitative",
  allowed: ["Multi-parameter (Panel)"], normal: ["Multi-parameter (Panel)"], loinc: "58410-2"
upsert_ref_rule "RDW-CV", name: "RDW-CV",                result_type: "numeric", low: 11.5, high: 14.5, unit: "%",       reference_value: "11.5 - 14.5", loinc: "788-0",  previous_names: ["RDW"]
upsert_ref_rule "RDW-SD", name: "RDW-SD",                result_type: "numeric", low: 39,   high: 46,   unit: "fL",      reference_value: "39 - 46",      loinc: "21000-5"
upsert_ref_rule "MONO",   name: "Monosit",               result_type: "numeric", low: 2,    high: 11,   unit: "%",       reference_value: "2 - 11",       loinc: "5905-5"
upsert_ref_rule "LYMPH",  name: "Limfosit",              result_type: "numeric", low: 18,   high: 42,   unit: "%",       reference_value: "18 - 42",      loinc: "736-9"
upsert_ref_rule "SEG",    name: "Segmen",                result_type: "numeric", low: 50,   high: 70,   unit: "%",       reference_value: "50 - 70",      loinc: "770-8",  previous_names: ["Neutrofil"]
upsert_ref_rule "BAND",   name: "Batang",                result_type: "numeric", low: 0,    high: 5,    unit: "%",       reference_value: "0 - 5",        loinc: "764-1"
upsert_ref_rule "EOS",    name: "Eosinofil",             result_type: "numeric", low: 1,    high: 3,    unit: "%",       reference_value: "1 - 3",        loinc: "713-8"
upsert_ref_rule "BASO",   name: "Basofil",               result_type: "numeric", low: 0,    high: 2,    unit: "%",       reference_value: "0 - 2",        loinc: "706-2"
upsert_ref_rule "MCHC",   name: "MCHC",                  result_type: "numeric", low: 32,   high: 36,   unit: "g/dL",    reference_value: "32 - 36",      loinc: "786-4"
upsert_ref_rule "MCH",    name: "MCH",                   result_type: "numeric", low: 27,   high: 33,   unit: "pg",      reference_value: "27 - 33",      loinc: "785-6"
upsert_ref_rule "MCV",    name: "MCV",                   result_type: "numeric", low: 80,   high: 100,  unit: "fL",      reference_value: "80 - 100",     loinc: "787-2"
upsert_ref_rule "RBC",    name: "ERITROSIT (Pria)",      result_type: "numeric", low: 4.5,  high: 5.9,  unit: "10⁶/µL", reference_value: "4.5 - 5.9",    loinc: "789-8",  previous_names: ["Eritrosit (Pria)"],   gender: "male"
upsert_ref_rule "RBC",    name: "ERITROSIT (Wanita)",    result_type: "numeric", low: 4.1,  high: 5.1,  unit: "10⁶/µL", reference_value: "4.1 - 5.1",    loinc: "789-8",  previous_names: ["Eritrosit (Wanita)"], gender: "female"
upsert_ref_rule "PLT",    name: "Trombosit",             result_type: "numeric", low: 150,  high: 450,  unit: "10³/µL", reference_value: "150 - 450",    loinc: "777-3"
upsert_ref_rule "BAS#",   name: "Basofil Absolut",       result_type: "numeric", low: 0.00, high: 0.10, unit: "10³/µL", reference_value: "0.00 - 0.10",  loinc: "704-7"
upsert_ref_rule "NEU#",   name: "Neutrofil Absolut",     result_type: "numeric", low: 2.00, high: 7.00, unit: "10³/µL", reference_value: "2.00 - 7.00",  loinc: "751-8"
upsert_ref_rule "EOS#",   name: "Eosinofil Absolut",     result_type: "numeric", low: 0.02, high: 0.50, unit: "10³/µL", reference_value: "0.02 - 0.50",  loinc: "711-2"
upsert_ref_rule "MON#",   name: "Monosit Absolut",       result_type: "numeric", low: 0.12, high: 1.20, unit: "10³/µL", reference_value: "0.12 - 1.20",  loinc: "742-7"
upsert_ref_rule "HCT",    name: "Hematokrit (Pria)",     result_type: "numeric", low: 41.0, high: 50.0, unit: "%",       reference_value: "41.0 - 50.0",  loinc: "4544-3",  previous_names: ["Hematokrit Pria"],   gender: "male"
upsert_ref_rule "HCT",    name: "Hematokrit (Wanita)",   result_type: "numeric", low: 36.0, high: 48.0, unit: "%",       reference_value: "36.0 - 48.0",  loinc: "4544-3",  previous_names: ["Hematokrit Wanita"], gender: "female"
upsert_ref_rule "MPV",    name: "MPV",                   result_type: "numeric", low: 7.0,  high: 11.0, unit: "fL",      reference_value: "7.0 - 11.0",   loinc: "32623-1"
upsert_ref_rule "PDW",    name: "PDW",                   result_type: "numeric", low: 9.0,  high: 17.0, unit: nil,      reference_value: "9.0 - 17.0",   loinc: "32207-3"
upsert_ref_rule "PCT",    name: "PCT",                   result_type: "numeric", low: 1.08, high: 2.82, unit: "mL/L",    reference_value: "1.08 - 2.82",  loinc: "10002"
upsert_ref_rule "PLCC",   name: "PLCC",                  result_type: "numeric", low: 30,   high: 90,   unit: "10⁹/L",  reference_value: "30 - 90",      loinc: "10013"
upsert_ref_rule "PLCR",   name: "PLCR",                  result_type: "numeric", low: 11.0, high: 45.0, unit: "%",       reference_value: "11.0 - 45.0",  loinc: "10014"
upsert_ref_rule "WBC",    name: "Lekosit",               result_type: "numeric", low: 4.5,  high: 11.0, unit: "10³/µL", reference_value: "4.5 - 11.0",   loinc: "6690-2",  previous_names: ["Leukosit"]
upsert_ref_rule "HGB",    name: "Hemoglobin (Pria)",     result_type: "numeric", low: 13.5, high: 17.5, unit: "g/dL",    reference_value: "13.5 - 17.5", loinc: "718-7",  previous_names: ["Hemoglobin Male"],   gender: "male"
upsert_ref_rule "HGB",    name: "Hemoglobin (Wanita)",   result_type: "numeric", low: 12.0, high: 15.5, unit: "g/dL",    reference_value: "12.0 - 15.5", loinc: "718-7",  previous_names: ["Hemoglobin Female"], gender: "female"

# ── LED ──
upsert_ref_rule "LED", name: "LED (Pria)",   result_type: "numeric", low: 0, high: 15, unit: "mm/jam", reference_value: "0 - 15",  loinc: "4537-7", gender: "male"
upsert_ref_rule "LED", name: "LED (Wanita)", result_type: "numeric", low: 0, high: 20, unit: "mm/jam", reference_value: "0 - 20",  loinc: "4537-7", gender: "female"

# ── Hematologi Tambahan (LOINC) ──
upsert_ref_rule "PHLEBO", name: "Phlebotomi", result_type: "qualitative",
  allowed: ["Selesai"], normal: ["Selesai"], loinc: "26515-7"
upsert_ref_rule "RETIC", name: "Retikulosit", result_type: "numeric",
  low: 0.5, high: 2.5, unit: "%", reference_value: "0.5 - 2.5", loinc: "17849-1"
upsert_ref_rule "CROSSMATCH", name: "Cross Match", result_type: "qualitative",
  allowed: ["Compatible (Cocok)", "Incompatible (Tidak Cocok)"],
  normal: ["Compatible (Cocok)"], abnormal: ["Incompatible (Tidak Cocok)"], loinc: "1250-7"
upsert_ref_rule "COOMBS-D", name: "Coombs Test Direk", result_type: "qualitative",
  allowed: %w[Positif Negatif], normal: %w[Negatif], abnormal: %w[Positif], loinc: "1007-4"
upsert_ref_rule "COOMBS-I", name: "Coombs Test Indirek", result_type: "qualitative",
  allowed: %w[Positif Negatif], normal: %w[Negatif], abnormal: %w[Positif], loinc: "890-4"
upsert_ref_rule "VITB12", name: "Vitamin B12", result_type: "numeric",
  low: 200, high: 900, unit: "pg/mL", reference_value: "200 - 900", loinc: "2132-9"
upsert_ref_rule "HAMSTEST", name: "Hams Test", result_type: "qualitative",
  allowed: %w[Positif Negatif], normal: %w[Negatif], abnormal: %w[Positif], loinc: "49019-1"
upsert_ref_rule "ITRATIO", name: "IT Ratio", result_type: "numeric",
  high: 0.20, unit: "Rasio", reference_value: "< 0.20", loinc: "30522-7"
upsert_ref_rule "DIFF",   name: "Hitung Jenis (DIFF)", result_type: "qualitative",
  allowed: ["Bervariasi per jenis sel"], normal: ["Bervariasi per jenis sel"], loinc: "21232-4"

# ── Golongan Darah ──
upsert_ref_rule "GOLDAR", name: "Golongan Darah", result_type: "qualitative",
  allowed: %w[A B AB O], normal: %w[A B AB O], loinc: "883-9"
upsert_ref_rule "GOLDAR", name: "Rhesus", result_type: "qualitative",
  allowed: ["Positif (+)", "Negatif (-)"], normal: ["Positif (+)"], abnormal: ["Negatif (-)"], loinc: "10331-7"

# ── Gula Darah Sewaktu ──
upsert_ref_rule "GDS", name: "GULA DARAH SEWAKTU", result_type: "numeric",
  high: 100, unit: "mg/dL",
  reference_value: "Normal: < 100 | Gangguan Toleransi: 100–126 | Diabetes: > 126",
  loinc: "1558-6"

# ── Elektrolit ──
upsert_ref_rule "CL", name: "Chloride (Cl)", result_type: "numeric",
  low: 98, high: 107, unit: "mmol/L", reference_value: "98 - 107", loinc: "2075-0"
upsert_ref_rule "K", name: "Kalium (K)", result_type: "numeric",
  low: 3.6, high: 5.2, unit: "mmol/L", reference_value: "3.6 - 5.2", loinc: "2823-3"
upsert_ref_rule "NA", name: "Natrium (Na)", result_type: "numeric",
  low: 135, high: 145, unit: "mmol/L", reference_value: "135 - 145", loinc: "2951-2"

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

  # ── Kimia Klinik Tambahan (LOINC) ──
upsert_ref_rule "TP",   name: "Total Protein",   result_type: "numeric", low: 6.4,  high: 8.3,  unit: "g/dL", reference_value: "6.4 - 8.3",  loinc: "2885-2"
upsert_ref_rule "ALB",  name: "Albumin",         result_type: "numeric", low: 3.5,  high: 5.0,  unit: "g/dL", reference_value: "3.5 - 5.0",  loinc: "1751-7"
upsert_ref_rule "AMY",  name: "Amilase Serum",   result_type: "numeric", low: 30,   high: 110,  unit: "U/L", reference_value: "30 - 110",   loinc: "1798-8"
upsert_ref_rule "LIP",  name: "Lipase Serum",    result_type: "numeric", low: 10,   high: 140,  unit: "U/L", reference_value: "10 - 140",   loinc: "3040-3"
upsert_ref_rule "LDH",  name: "Laktat Dehidrogenase", result_type: "numeric", low: 140, high: 280, unit: "U/L", reference_value: "140 - 280", loinc: "2532-0"

# ── Fungsi Ginjal ──
upsert_ref_rule "CRE", name: "CREATININE (Pria)",   result_type: "numeric", low: 0.7, high: 1.2, unit: "mg/dL", reference_value: "0.7 - 1.2", loinc: "2160-0", previous_names: ["Kreatinin (Pria)", "Adult Male Creatinine"],   gender: "male"
upsert_ref_rule "CRE", name: "CREATININE (Wanita)", result_type: "numeric", low: 0.5, high: 1.0, unit: "mg/dL", reference_value: "0.5 - 1.0", loinc: "2160-0", previous_names: ["Kreatinin (Wanita)", "Adult Female Creatinine"], gender: "female"
upsert_ref_rule "UR",  name: "UREUM",               result_type: "numeric", low: 15,  high: 45,  unit: "mg/dL", reference_value: "15 - 45",   loinc: "3094-0", previous_names: ["Ureum", "BUN Adult"]

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
  allowed: KUNING_NORMAL + ["Merah", "Coklat", "Keruh"], normal: KUNING_NORMAL, abnormal: ["Merah", "Coklat"], loinc: "13481-7"
upsert_ref_rule "URINE-L", name: "Kejernihan",         result_type: "qualitative",
  allowed: %w[Jernih Keruh], normal: %w[Jernih], abnormal: %w[Keruh], loinc: "5767-9"
upsert_ref_rule "URINE-L", name: "Berat Jenis",        result_type: "numeric", low: 1.003, high: 1.030, reference_value: "1.003 - 1.030", loinc: "5812-7"
upsert_ref_rule "URINE-L", name: "pH",                 result_type: "numeric", low: 4.5,   high: 8.0,   reference_value: "4.5 - 8.0", loinc: "5803-6"
upsert_ref_rule "URINE-L", name: "Protein",            result_type: "qualitative",
  allowed: %w[Negatif Positif +1 +2 +3], normal: %w[Negatif], abnormal: %w[Positif +1 +2 +3], loinc: "20454-5"
upsert_ref_rule "URINE-L", name: "Glukosa",            result_type: "qualitative",
  allowed: %w[Negatif Positif +1 +2 +3], normal: %w[Negatif], abnormal: %w[Positif +1 +2 +3], loinc: "25428-4"
upsert_ref_rule "URINE-L", name: "Keton",              result_type: "qualitative",
  allowed: %w[Negatif Positif +1 +2 +3], normal: %w[Negatif], abnormal: %w[Positif +1 +2 +3], loinc: "2514-8"
upsert_ref_rule "URINE-L", name: "Bilirubin",          result_type: "qualitative",
  allowed: %w[Negatif Positif +1 +2 +3], normal: %w[Negatif], abnormal: %w[Positif +1 +2 +3], loinc: "5770-3"
upsert_ref_rule "URINE-L", name: "Darah",              result_type: "qualitative",
  allowed: %w[Negatif Positif +1 +2 +3], normal: %w[Negatif], abnormal: %w[Positif +1 +2 +3], loinc: "5794-7"
upsert_ref_rule "URINE-L", name: "Nitrit",             result_type: "qualitative",
  allowed: %w[Negatif Positif], normal: %w[Negatif], abnormal: %w[Positif], loinc: "5797-0"
upsert_ref_rule "URINE-L", name: "Urobilinogen",       result_type: "numeric",
  low: 0.2, high: 1.0, unit: "mg/dL", reference_value: "0.2 - 1.0 mg/dL", loinc: "5802-8"
upsert_ref_rule "URINE-L", name: "Esterase Lekosit",  result_type: "qualitative",
  allowed: %w[Negatif Positif +1 +2 +3], normal: %w[Negatif], abnormal: %w[Positif +1 +2 +3], loinc: "5799-6"

# ── Sedimen Urine ──
upsert_ref_rule "URINE-S", name: "Eritrosit Sedimen", result_type: "numeric", high: 2, unit: "/LPB (hpf)", reference_value: "0 - 2", loinc: "5811-9"
upsert_ref_rule "URINE-S", name: "Leukosit Sedimen",  result_type: "numeric", high: 5, unit: "/LPB (hpf)", reference_value: "0 - 5", loinc: "5821-8"
upsert_ref_rule "URINE-S", name: "Epitel Sel",        result_type: "qualitative",
  allowed: ["Negatif", "Positif (+) Rendah", "Positif (+) Sedang", "Positif (+) Tinggi"],
  normal: ["Negatif", "Positif (+) Rendah"],
  abnormal: ["Positif (+) Sedang", "Positif (+) Tinggi"], loinc: "5788-5"
upsert_ref_rule "URINE-S", name: "Silinder", result_type: "qualitative", allowed: %w[Negatif Positif], normal: %w[Negatif], abnormal: %w[Positif]
upsert_ref_rule "URINE-S", name: "Kristal",  result_type: "qualitative", allowed: %w[Negatif Positif], normal: %w[Negatif], abnormal: %w[Positif]
upsert_ref_rule "URINE-S", name: "Jamur",    result_type: "qualitative", allowed: %w[Negatif Positif], normal: %w[Negatif], abnormal: %w[Positif]
upsert_ref_rule "URINE-S", name: "Bakteri",  result_type: "qualitative", allowed: %w[Negatif Positif], normal: %w[Negatif], abnormal: %w[Positif]

# ── Faeces Lengkap (LOINC) ──
upsert_ref_rule "FAECES", name: "Warna",                result_type: "qualitative",
  allowed: ["Cokelat", "Kuning", "Hijau", "Hitam", "Merah", "Pucat"],
  normal: ["Cokelat"], abnormal: ["Hitam", "Merah", "Pucat"], loinc: "9397-5"
upsert_ref_rule "FAECES", name: "Konsistensi",          result_type: "qualitative",
  allowed: ["Lunak / Berbentuk", "Cair", "Keras", "Lembek", "Berdarah"],
  normal: ["Lunak / Berbentuk"], abnormal: ["Cair", "Keras", "Berdarah"], loinc: "48021-0"
upsert_ref_rule "FAECES", name: "Lendir",               result_type: "qualitative",
  allowed: %w[Negatif Positif], normal: %w[Negatif], abnormal: %w[Positif], loinc: "43398-7"
upsert_ref_rule "FAECES", name: "Darah Makroskopis",    result_type: "qualitative",
  allowed: %w[Negatif Positif], normal: %w[Negatif], abnormal: %w[Positif], loinc: "14725-6"
upsert_ref_rule "FAECES", name: "Eritrosit Mikroskopis",result_type: "numeric", high: 1, unit: "/LPB", reference_value: "0 - 1", loinc: "19005-8"
upsert_ref_rule "FAECES", name: "Leukosit Mikroskopis", result_type: "numeric", high: 1, unit: "/LPB", reference_value: "0 - 1", loinc: "6762-9"
upsert_ref_rule "FAECES", name: "Amoeba / Parasit",     result_type: "qualitative",
  allowed: %w[Negatif Positif], normal: %w[Negatif], abnormal: %w[Positif], loinc: "10701-1"
upsert_ref_rule "FAECES", name: "Telur Cacing",         result_type: "qualitative",
  allowed: %w[Negatif Positif], normal: %w[Negatif], abnormal: %w[Positif], loinc: "10703-7"
upsert_ref_rule "FAECES", name: "Darah Samar",          result_type: "qualitative",
  allowed: %w[Negatif Positif], normal: %w[Negatif], abnormal: %w[Positif], loinc: "29771-3"

# ── Mikrobiologi (LOINC) ──
upsert_ref_rule "GRAM",   name: "Pewarnaan Gram",         result_type: "qualitative",
  allowed: ["Flora Normal", "Tidak ditemukan bakteri", "Bakteri Gram Positif", "Bakteri Gram Negatif"],
  normal: ["Flora Normal", "Tidak ditemukan bakteri"],
  abnormal: ["Bakteri Gram Positif", "Bakteri Gram Negatif"], loinc: "664-3"
upsert_ref_rule "BTA",    name: "Pewarnaan BTA",          result_type: "qualitative",
  allowed: %w[Negatif Positif], normal: %w[Negatif], abnormal: %w[Positif], loinc: "11545-1"
upsert_ref_rule "KULTUR", name: "Kultur & Sensitivitas",  result_type: "text",
  reference_value: "Tidak ada pertumbuhan kuman patogen", loinc: "632-4"
upsert_ref_rule "KOH",    name: "Pewarnaan Jamur (KOH)",  result_type: "qualitative",
  allowed: ["Negatif", "Positif (+) Hifa", "Positif (+) Spora", "Positif (+) Pseudohifa"],
  normal: ["Negatif"], abnormal: ["Positif (+) Hifa", "Positif (+) Spora", "Positif (+) Pseudohifa"], loinc: "625-8"

# ── Patologi Anatomi (LOINC) ──
upsert_ref_rule "HPA",      name: "Histopatologi (Biopsi)",  result_type: "text",
  reference_value: "Jinak (Benigna) / Tidak ditemukan keganasan", loinc: "49015-9"
upsert_ref_rule "SITOLOGI", name: "Sitologi Non-Ginekologi", result_type: "text",
  reference_value: "Negatif untuk keganasan", loinc: "33717-0"
upsert_ref_rule "FNAB",     name: "Fine Needle Aspiration",  result_type: "text",
  reference_value: "Interpretasi sitologi sel aspirat", loinc: "44835-7"
upsert_ref_rule "PAP",      name: "Pap Smear",               result_type: "text",
  reference_value: "NILM (Negative for Intraepithelial Lesion or Malignancy)", loinc: "10524-7"

# ── Source reference rules for computed values (must exist before formula can fire) ──
upsert_ref_rule "LYM#",      name: "Limfosit Absolut", result_type: "numeric", low: 1.0, high: 4.0,  unit: "10³/µL", reference_value: "1.0 - 4.0"
upsert_ref_rule "CHOL",      name: "Cholesterol",      result_type: "numeric", low: 0,   high: 200,  unit: "mg/dL",   reference_value: "< 200"
upsert_ref_rule "TG",        name: "Trigliserida",     result_type: "numeric", low: 0,   high: 150,  unit: "mg/dL",   reference_value: "< 150"
upsert_ref_rule "HDL",       name: "HDL",              result_type: "numeric", low: 40,  high: 999,  unit: "mg/dL",   reference_value: "> 40"
upsert_ref_rule "TOT_BIL",   name: "Bilirubin Total",  result_type: "numeric", low: 0.0, high: 1.2,  unit: "mg/dL",   reference_value: "0.0 - 1.2"
upsert_ref_rule "DIREK_BIL", name: "Bilirubin Direk",  result_type: "numeric", low: 0.0, high: 0.3,  unit: "mg/dL",   reference_value: "0.0 - 0.3"

# ── Computed reference rules (auto-fill from sibling results) ──
upsert_ref_rule "NLR",        name: "NLR",                result_type: "numeric", low: 1.0,  high: 3.0,  reference_value: "1.0 - 3.0",
                             formula_expression: "NEU# / LYM#",            formula_inputs: [{ "code" => "NEU#" }, { "code" => "LYM#" }]
upsert_ref_rule "LDL-CALC",   name: "LDL Cholesterol",    result_type: "numeric", low: 0,    high: 100,  unit: "mg/dL", reference_value: "< 100",
                             formula_expression: "CHOL - (TG / 5) - HDL",   formula_inputs: [{ "code" => "CHOL" }, { "code" => "TG" }, { "code" => "HDL" }]
upsert_ref_rule "CHOL-RATIO", name: "Cholesterol Ratio",  result_type: "numeric", low: 0,    high: 5,    reference_value: "< 5",
                             formula_expression: "CHOL / HDL",              formula_inputs: [{ "code" => "CHOL" }, { "code" => "HDL" }]
upsert_ref_rule "INDIREK",    name: "Bilirubin Indirek",  result_type: "numeric", low: 0.0,  high: 1.1,  unit: "mg/dL", reference_value: "0.0 - 1.1",
                             formula_expression: "TOT_BIL - DIREK_BIL",     formula_inputs: [{ "code" => "TOT_BIL" }, { "code" => "DIREK_BIL" }]
upsert_ref_rule "GLOB",       name: "Globulin",           result_type: "numeric", low: 2.0,  high: 3.5,  unit: "g/dL", reference_value: "2.0 - 3.5",
                             formula_expression: "TP - ALB",                formula_inputs: [{ "code" => "TP" }, { "code" => "ALB" }], loinc: "2336-6"

puts "  ✅ #{ReferenceRule.count} reference rules seeded"

# ─── Sample Specimens & Works ─────────────────────────────────────────────────

puts "🧪 Creating sample specimens..."

if Specimen.count < 5
  exam_ids_for = lambda do |codes|
    exams = Examination.where(code: codes).index_by(&:code)
    codes.map { |code| exams.fetch(code).id }
  end

  darah_lengkap_ids = exam_ids_for.call(darah_lengkap_codes)
  elektrolit_ids = exam_ids_for.call(elektrolit_codes)
  fungsi_ginjal_ids = exam_ids_for.call(fungsi_ginjal_codes)

  profil_lemak  = Examination.find_by!(code: "LEMAK")
  hba1c         = Examination.find_by!(code: "HBA1C")
  anti_hiv      = Examination.find_by!(code: "HIV")
  urine_l       = Examination.find_by!(code: "URINE-L")
  gula_darah_sewaktu = Examination.find_by!(code: "GDS")

  sample_patients = [
    {
      patient_id: "P-10001", patient_name: "Budi Santoso",      birth_date: "1985-04-12",
      gender: "Laki-laki",   medical_record_id: "RM-2024-001",  lab_id: "LAB-01",
      department: "Penyakit Dalam", referring_doctor: "dr. Andi Kusuma, Sp.PD",
      examination_ids: darah_lengkap_ids + [profil_lemak.id]
    },
    {
      patient_id: "P-10002", patient_name: "Siti Rahayu",       birth_date: "1992-07-23",
      gender: "Perempuan",   medical_record_id: "RM-2024-002",  lab_id: "LAB-01",
      department: "Kebidanan", referring_doctor: "dr. Dewi Lestari, Sp.OG",
      examination_ids: darah_lengkap_ids + [hba1c.id]
    },
    {
      patient_id: "P-10003", patient_name: "Ahmad Wijaya",      birth_date: "1970-11-05",
      gender: "Laki-laki",   medical_record_id: "RM-2024-003",  lab_id: "LAB-01",
      department: "Kardiologi", referring_doctor: "dr. Hendra Gunawan, Sp.JP",
      examination_ids: [profil_lemak.id, hba1c.id, gula_darah_sewaktu.id, anti_hiv.id]
    },
    {
      patient_id: "P-10004", patient_name: "Dewi Susanti",      birth_date: "1955-02-28",
      gender: "Perempuan",   medical_record_id: nil,             lab_id: "LAB-02",
      department: "Geriatri",
      examination_ids: elektrolit_ids + fungsi_ginjal_ids + darah_lengkap_ids
    },
    {
      patient_id: "P-10005", patient_name: "Rizki Pratama",     birth_date: "2001-09-18",
      gender: "Laki-laki",   medical_record_id: "RM-2024-005",  lab_id: "LAB-01",
      department: "IGD",
      examination_ids: darah_lengkap_ids + [urine_l.id, anti_hiv.id]
    },
  ]

  sample_patients.each do |data|
    if Specimen.exists?(patient_id: data[:patient_id])
      puts "  ⏭️  #{data[:patient_name]} sudah ada, skip"
      next
    end

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

  # Map: primary work exam code → seeded result rows.
  sample_results = {
    "RDW-CV" => [
      { exam: "RDW-CV", ref: "RDW-CV",              val: "11.8", unit: "%"       },
      { exam: "RDW-SD", ref: "RDW-SD",              val: "42",   unit: "fL"      },
      { exam: "MONO",   ref: "Monosit",             val: "8.4",  unit: "%"       },
      { exam: "LYMPH",  ref: "Limfosit",            val: "34.6", unit: "%"       },
      { exam: "SEG",    ref: "Segmen",              val: "49.5", unit: "%"       },
      { exam: "BAND",   ref: "Batang",              val: "2.0",  unit: "%"       },
      { exam: "EOS",    ref: "Eosinofil",           val: "7.0",  unit: "%"       },
      { exam: "BASO",   ref: "Basofil",             val: "0.5",  unit: "%"       },
      { exam: "MCHC",   ref: "MCHC",                val: "34",   unit: "g/dL"    },
      { exam: "MCH",    ref: "MCH",                 val: "27",   unit: "pg"      },
      { exam: "MCV",    ref: "MCV",                 val: "82",   unit: "fL"      },
      { exam: "RBC",    ref: "ERITROSIT (Pria)",    val: "5.58", unit: "10⁶/µL" },
      { exam: "PLT",    ref: "Trombosit",           val: "333",  unit: "10³/µL" },
      { exam: "HCT",    ref: "Hematokrit",          val: "45.5", unit: "%"       },
      { exam: "WBC",    ref: "Lekosit",             val: "7.6",  unit: "10³/µL" },
      { exam: "HGB",    ref: "Hemoglobin (Pria)",   val: "15.3", unit: "g/dL"    },
    ],
    "CL" => [
      { exam: "CL", ref: "Chloride (Cl)", val: "101", unit: "mmol/L" },
      { exam: "K",  ref: "Kalium (K)",    val: "4.2", unit: "mmol/L" },
      { exam: "NA", ref: "Natrium (Na)",  val: "139", unit: "mmol/L" },
    ],
    "CRE" => [
      { exam: "CRE", ref: "CREATININE (Pria)", val: "1.1", unit: "mg/dL" },
      { exam: "UR",  ref: "UREUM",             val: "32",  unit: "mg/dL" },
    ],
    "GDS" => [
      { ref: "GULA DARAH SEWAKTU", val: "95", unit: "mg/dL" },
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
      ref_exam = row[:exam] ? Examination.find_by!(code: row[:exam]) : exam
      ref_rule = ReferenceRule.find_by!(examination: ref_exam, name: row[:ref])

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

# ─── Complete Specimen (all examinations, verified) ────────────────────────────

puts "🏁 Creating one complete specimen (all exams, all verified)..."

def default_value_for(rule)
  case rule.result_type
  when "numeric"
    if rule.numeric_low_value.present? && rule.numeric_high_value.present?
      ((rule.numeric_low_value + rule.numeric_high_value) / 2.0).round(2).to_s
    elsif rule.numeric_low_value.present?
      (rule.numeric_low_value + 0.1).round(2).to_s
    elsif rule.numeric_high_value.present?
      (rule.numeric_high_value - 0.1).round(2).to_s
    else
      "0"
    end
  when "qualitative"
    Array(rule.normal_values).first.presence || Array(rule.allowed_values).first.presence || "Negatif"
  when "text"
    rule.reference_value.presence || "Normal"
  else
    "-"
  end
end

complete_patient_id = "P-99999"
supervisor_user = User.find_by!(email: "supervisor@lisa.local")
tech1_user      = User.find_by!(email: "tech1@lisa.local")
all_exam_ids    = Examination.active.pluck(:id)

complete_specimen = Specimen.find_by(patient_id: complete_patient_id)

if complete_specimen.nil?
  create_result = Specimens::CreateService.call(
    patient_id:          complete_patient_id,
    patient_name:        "Lengkap Sari (Demo Complete)",
    birth_date:          "1980-06-15",
    gender:              "Laki-laki",
    medical_record_id:   "RM-COMPLETE-001",
    lab_id:              "LAB-01",
    department:          "Penyakit Dalam",
    referring_doctor:    "dr. Andi Kusuma, Sp.PD",
    dianognes:           "Pemeriksaan laboratorium lengkap (medical check-up)",
    collection_datetime: Time.current,
    examination_ids:     all_exam_ids
  )

  if create_result.success?
    complete_specimen = create_result.specimen
  else
    puts "  ⚠️  Gagal membuat complete specimen: #{create_result.errors.join(', ')}"
  end
end

if complete_specimen
  works = complete_specimen.works.includes(:examination, examination_results: :reference_rule).to_a

  works.each do |work|
    exam = work.examination
    enum_gender = ReferenceRule.specimen_gender_to_enum(complete_specimen.gender)

    grouped_exams = if exam.label_group.present?
      Examination.where(label_group: exam.label_group)
    else
      Examination.where(id: exam.id)
    end

    rules = grouped_exams.flat_map(&:reference_rules).select { |r| r.gender.nil? || r.gender.to_s == enum_gender.to_s }
    chosen = rules.empty? ? grouped_exams.flat_map(&:reference_rules) : rules

    chosen.each do |rule|
      next if rule.formula_expression.present?
      next if work.examination_results.exists?(reference_rule_id: rule.id)

      ExaminationResult.create!(
        work:             work,
        reference_rule:   rule,
        result_value:     default_value_for(rule),
        result_unit:      rule.unit,
        source:           "manual",
        entered_by:       tech1_user.id,
        verified_by:      supervisor_user.id,
        verified_at:      Time.current
      )
    end

    work.update!(status: Work.statuses[:validated], validated_at: Time.current, verified_at: Time.current) if work.pending?
    work.reload
    work.update!(status: Work.statuses[:verified], verified_at: Time.current) unless work.verified?
  end

  complete_specimen.update!(status: Specimen.statuses[:complete])
  puts "  ✅ Specimen #{complete_specimen.order_number} complete (#{works.size} works, all verified)"
end

puts ""
puts "✅ Seeding selesai!"
puts ""
puts "📋 Kredensial login (password: Password@123):"
puts "   admin@lisa.local       → admin"
puts "   supervisor@lisa.local  → lab_supervisor"
puts "   tech1@lisa.local       → lab_technician"
puts "   tech2@lisa.local       → lab_technician"
puts "   doctor@lisa.local      → doctor"
