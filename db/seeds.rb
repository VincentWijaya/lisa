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

darah_lengkap_codes = %w[RDW-CV RDW-SD MONO LYMPH SEG BAND EOS BASO MCHC MCH MCV RBC PLT HCT WBC HGB BAS# NEU# EOS# MON# LYM# MPV PDW PCT PLCC PLCR].freeze
elektrolit_codes = %w[CL K NA].freeze
fungsi_ginjal_codes = %w[CRE UR].freeze

examinations_data = [
  # ── HEMATOLOGI ──
  { code: "DL",         name: "Hematologi Lengkap",          category: "Hematologi",    label_group: "A1 Hematologi", specimen_type: "Darah EDTA", default_result_type: "qualitative", default_unit: nil },
  { code: "IPF",        name: "IPF (Immature Platelet)",    category: "Hematologi",    label_group: "A1 Hematologi", specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "%" },
  { code: "AEC",        name: "Hitung Eosinofil",           category: "Hematologi",    label_group: "A1 Hematologi", specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "/µL" },
  { code: "BMP",        name: "Gambaran Sumsum Tulang",     category: "Hematologi",    label_group: "A1 Hematologi", specimen_type: "Aspirat",    default_result_type: "qualitative", default_unit: "Interpretasi" },
  { code: "SIT-KEL",    name: "Sitologi Kelenjar (MGG)",    category: "Hematologi",    label_group: "A1 Hematologi", specimen_type: "Aspirat",    default_result_type: "qualitative", default_unit: "Interpretasi" },
  { code: "ITRATIO",    name: "IT Ratio",                   category: "Hematologi",    label_group: "A1 Hematologi", specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "Rasio" },
  { code: "NAP",        name: "Pewarnaan Sitokimia - NAP",  category: "Hematologi",    label_group: "A1 Hematologi", specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "Score" },

  # ── CBC Panel Breakdown ──
  { code: "RDW-CV",     name: "RDW-CV",                      category: "Hematologi",    label_group: "Darah Lengkap", specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "%" },
  { code: "RDW-SD",     name: "RDW-SD",                      category: "Hematologi",    label_group: "Darah Lengkap", specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "fL" },
  { code: "MONO",       name: "Monosit",                     category: "Hematologi",    label_group: "Darah Lengkap", specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "%" },
  { code: "LYMPH",      name: "Limfosit",                    category: "Hematologi",    label_group: "Darah Lengkap", specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "%" },
  { code: "SEG",        name: "Segmen",                      category: "Hematologi",    label_group: "Darah Lengkap", specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "%" },
  { code: "BAND",       name: "Batang",                      category: "Hematologi",    label_group: "Darah Lengkap", specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "%" },
  { code: "EOS",        name: "Eosinofil",                   category: "Hematologi",    label_group: "Darah Lengkap", specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "%" },
  { code: "BASO",       name: "Basofil",                     category: "Hematologi",    label_group: "Darah Lengkap", specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "%" },
  { code: "MCHC",       name: "MCHC",                        category: "Hematologi",    label_group: "Darah Lengkap", specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "g/dL" },
  { code: "MCH",        name: "MCH",                         category: "Hematologi",    label_group: "Darah Lengkap", specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "pg" },
  { code: "MCV",        name: "MCV",                         category: "Hematologi",    label_group: "Darah Lengkap", specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "fL" },
  { code: "RBC",        name: "ERITROSIT",                   category: "Hematologi",    label_group: "Darah Lengkap", specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "10⁶/µL" },
  { code: "PLT",        name: "Trombosit",                   category: "Hematologi",    label_group: "Darah Lengkap", specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "10³/µL" },
  { code: "HCT",        name: "Hematokrit",                  category: "Hematologi",    label_group: "Darah Lengkap", specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "%" },
  { code: "WBC",        name: "Lekosit",                     category: "Hematologi",    label_group: "Darah Lengkap", specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "10³/µL" },
  { code: "HGB",        name: "Hemoglobin",                  category: "Hematologi",    label_group: "Darah Lengkap", specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "g/dL" },
  { code: "BAS#",       name: "Basofil Absolut",             category: "Hematologi",    label_group: "Darah Lengkap", specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "10³/µL" },
  { code: "NEU#",       name: "Neutrofil Absolut",           category: "Hematologi",    label_group: "Darah Lengkap", specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "10³/µL" },
  { code: "EOS#",       name: "Eosinofil Absolut",           category: "Hematologi",    label_group: "Darah Lengkap", specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "10³/µL" },
  { code: "MON#",       name: "Monosit Absolut",             category: "Hematologi",    label_group: "Darah Lengkap", specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "10³/µL" },
  { code: "MPV",        name: "MPV",                         category: "Hematologi",    label_group: "Darah Lengkap", specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "fL" },
  { code: "PDW",        name: "PDW",                         category: "Hematologi",    label_group: "Darah Lengkap", specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: nil },
  { code: "PCT",        name: "PCT",                         category: "Hematologi",    label_group: "Darah Lengkap", specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "mL/L" },
  { code: "PLCC",       name: "PLCC",                        category: "Hematologi",    label_group: "Darah Lengkap", specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "10⁹/L" },
  { code: "PLCR",       name: "PLCR",                        category: "Hematologi",    label_group: "Darah Lengkap", specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "%" },
  { code: "LED",        name: "LED",                         category: "Hematologi",    label_group: nil,             specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "mm/jam" },
  { code: "DIFF",       name: "Hitung Jenis (DIFF)",         category: "Hematologi",    label_group: "Darah Lengkap", specimen_type: "Darah EDTA", default_result_type: "qualitative", default_unit: nil },
  { code: "GOLDAR",     name: "Golongan Darah",              category: "Hematologi",    label_group: "Golongan Darah",specimen_type: "Darah EDTA", default_result_type: "qualitative", default_unit: nil },

  # ── HEMOSTASIS ──
  { code: "HEMO-PANEL", name: "Hemostasis Lengkap",          category: "Hemostasis",    label_group: "A2 Hemostasis", specimen_type: "Plasma Sitrat", default_result_type: "qualitative", default_unit: nil },
  { code: "BT",         name: "Masa Perdarahan (BT)",        category: "Hemostasis",    label_group: "A2 Hemostasis", specimen_type: "Darah Kapiler",default_result_type: "numeric",     default_unit: "menit" },
  { code: "PT",         name: "Masa Protrombin Plasma (PT)", category: "Hemostasis",    label_group: "A2 Hemostasis", specimen_type: "Plasma Sitrat", default_result_type: "numeric",     default_unit: "detik" },
  { code: "APTT",       name: "APTT",                        category: "Hemostasis",    label_group: "A2 Hemostasis", specimen_type: "Plasma Sitrat", default_result_type: "numeric",     default_unit: "detik" },
  { code: "TT",         name: "Masa Trombin (TT)",           category: "Hemostasis",    label_group: "A2 Hemostasis", specimen_type: "Plasma Sitrat", default_result_type: "numeric",     default_unit: "detik" },
  { code: "FIBRINOGEN", name: "Fibrinogen",                  category: "Hemostasis",    label_group: "A2 Hemostasis", specimen_type: "Plasma Sitrat", default_result_type: "numeric",     default_unit: "mg/dL" },
  { code: "D-DIMER",    name: "D-Dimer",                     category: "Hemostasis",    label_group: "A2 Hemostasis", specimen_type: "Plasma Sitrat", default_result_type: "numeric",     default_unit: "mg/L" },
  { code: "ACT",        name: "ACT (Activated Clotting)",    category: "Hemostasis",    label_group: "A2 Hemostasis", specimen_type: "Darah Lengkap",default_result_type: "numeric",     default_unit: "detik" },
  { code: "RL",         name: "Rumpell Leede",               category: "Hemostasis",    label_group: "A2 Hemostasis", specimen_type: "Darah Lengkap",default_result_type: "qualitative", default_unit: "Interpretasi" },
  { code: "AGR-PLT",    name: "Agregasi Trombosit",          category: "Hemostasis",    label_group: "A2 Hemostasis", specimen_type: "PRP",          default_result_type: "qualitative", default_unit: "%" },
  { code: "VISKOSITAS", name: "Viskositas Darah & Plasma",   category: "Hemostasis",    label_group: "A2 Hemostasis", specimen_type: "Darah EDTA", default_result_type: "qualitative", default_unit: "cP" },
  { code: "AT3",        name: "AT III",                      category: "Hemostasis",    label_group: "A2 Hemostasis", specimen_type: "Plasma Sitrat", default_result_type: "numeric",     default_unit: "%" },
  { code: "FVIII",      name: "Assay Faktor VIII",           category: "Hemostasis",    label_group: "A2 Hemostasis", specimen_type: "Plasma Sitrat", default_result_type: "numeric",     default_unit: "%" },
  { code: "FIX",        name: "Assay Faktor IX",             category: "Hemostasis",    label_group: "A2 Hemostasis", specimen_type: "Plasma Sitrat", default_result_type: "numeric",     default_unit: "%" },
  { code: "VWF",        name: "vWF Antigen/Activity",        category: "Hemostasis",    label_group: "A2 Hemostasis", specimen_type: "Plasma Sitrat", default_result_type: "numeric",     default_unit: "%" },

  # ── HEMOLITIK / TAMBAHAN ──
  { code: "SUGAR-WATER",name: "Sugar Water Test",           category: "Hemolitik",     label_group: "A3 Tes Hemolitik", specimen_type: "Darah EDTA", default_result_type: "qualitative", default_unit: "Interpretasi" },
  { code: "HAMSTEST",   name: "Ham's Test",                  category: "Hemolitik",     label_group: "A3 Tes Hemolitik", specimen_type: "Darah EDTA", default_result_type: "qualitative", default_unit: "Interpretasi" },
  { code: "G6PD",       name: "G6PD Eritrosit",              category: "Hemolitik",     label_group: "A3 Tes Hemolitik", specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "U/g Hb" },
  { code: "COOMBS-D",   name: "Coombs Test Direk",           category: "Hemolitik",     label_group: "A3 Tes Hemolitik", specimen_type: "Darah EDTA", default_result_type: "qualitative", default_unit: "Interpretasi" },
  { code: "COOMBS-I",   name: "Coombs Test Indirek",         category: "Hemolitik",     label_group: "A3 Tes Hemolitik", specimen_type: "Darah Beku", default_result_type: "qualitative", default_unit: "Interpretasi" },
  { code: "OFT",        name: "Resistensi Osmotik (OFT)",    category: "Hemolitik",     label_group: "A3 Tes Hemolitik", specimen_type: "Darah EDTA", default_result_type: "qualitative", default_unit: "% NaCl" },
  { code: "PHLEBO",     name: "Phlebotomi",                  category: "Hematologi",    label_group: nil,               specimen_type: "Darah EDTA", default_result_type: "qualitative", default_unit: nil },
  { code: "RETIC",      name: "Retikulosit",                 category: "Hematologi",    label_group: nil,               specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "%" },
  { code: "CROSSMATCH", name: "Cross Match",                 category: "Hematologi",    label_group: nil,               specimen_type: "Darah EDTA", default_result_type: "qualitative", default_unit: nil },
  { code: "VITB12",     name: "Vitamin B12",                 category: "Hematologi",    label_group: nil,               specimen_type: "Darah Beku", default_result_type: "numeric",     default_unit: "pg/mL" },

  # ── KIMIA KLINIK ──
  { code: "CL",         name: "Chloride (Cl)",               category: "Kimia Klinik",  label_group: "Elektrolit",      specimen_type: "Darah Beku", default_result_type: "numeric",     default_unit: "mmol/L" },
  { code: "K",          name: "Kalium (K)",                  category: "Kimia Klinik",  label_group: "Elektrolit",      specimen_type: "Darah Beku", default_result_type: "numeric",     default_unit: "mmol/L" },
  { code: "NA",         name: "Natrium (Na)",                category: "Kimia Klinik",  label_group: "Elektrolit",      specimen_type: "Darah Beku", default_result_type: "numeric",     default_unit: "mmol/L" },
  { code: "CRE",        name: "CREATININE",                  category: "Kimia Klinik",  label_group: "Fungsi Ginjal",   specimen_type: "Darah Beku", default_result_type: "numeric",     default_unit: "mg/dL" },
  { code: "UR",         name: "UREUM",                       category: "Kimia Klinik",  label_group: "Fungsi Ginjal",   specimen_type: "Darah Beku", default_result_type: "numeric",     default_unit: "mg/dL" },
  { code: "GDS",        name: "GULA DARAH SEWAKTU",          category: "Kimia Klinik",  label_group: nil,               specimen_type: "Darah Beku", default_result_type: "numeric",     default_unit: "mg/dL" },
  { code: "HBA1C",      name: "Panel HbA1C",                 category: "Kimia Klinik",  label_group: "HbA1C",           specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "%" },
  { code: "LEMAK",      name: "Profil Lemak",                category: "Kimia Klinik",  label_group: "Profil Lemak",    specimen_type: "Darah Beku", default_result_type: "numeric",     default_unit: "mg/dL" },
  { code: "FUNGSI-H",   name: "Fungsi Hati",                 category: "Kimia Klinik",  label_group: "Fungsi Hati",     specimen_type: "Darah Beku", default_result_type: "numeric",     default_unit: "U/L" },
  { code: "TP",         name: "Total Protein",               category: "Kimia Klinik",  label_group: nil,               specimen_type: "Darah Beku", default_result_type: "numeric",     default_unit: "g/dL" },
  { code: "ALB",        name: "Albumin",                     category: "Kimia Klinik",  label_group: nil,               specimen_type: "Darah Beku", default_result_type: "numeric",     default_unit: "g/dL" },
  { code: "AMY",        name: "Amilase Serum",               category: "Kimia Klinik",  label_group: nil,               specimen_type: "Darah Beku", default_result_type: "numeric",     default_unit: "U/L" },
  { code: "LIP",        name: "Lipase Serum",                category: "Kimia Klinik",  label_group: nil,               specimen_type: "Darah Beku", default_result_type: "numeric",     default_unit: "U/L" },
  { code: "LDH",        name: "Laktat Dehidrogenase",        category: "Kimia Klinik",  label_group: nil,               specimen_type: "Darah Beku", default_result_type: "numeric",     default_unit: "U/L" },

  # ── SEROIMUNOLOGI / HEPATITIS ──
  { code: "HIV",        name: "Anti HIV",                    category: "Seroimunologi", label_group: nil,               specimen_type: "Darah Beku", default_result_type: "qualitative", default_unit: nil },
  { code: "VDRL",       name: "VDRL",                        category: "Seroimunologi", label_group: nil,               specimen_type: "Darah Beku", default_result_type: "qualitative", default_unit: nil },
  { code: "ANTI-HBS",   name: "Anti HBs",                    category: "Seroimunologi", label_group: "D3 Hepatitis",    specimen_type: "Darah Beku", default_result_type: "qualitative", default_unit: nil },
  { code: "HBSAG",      name: "HBsAg",                       category: "Seroimunologi", label_group: "D3 Hepatitis",    specimen_type: "Darah Beku", default_result_type: "qualitative", default_unit: nil },

  # ── URINALISIS ──
  { code: "URINE-L",    name: "Urine Lengkap",               category: "Urinalisis",    label_group: "Urine Lengkap",   specimen_type: "Urine Rutin",default_result_type: "qualitative", default_unit: nil },
  { code: "URINE-S",    name: "Sedimen Urine",               category: "Urinalisis",    label_group: "Sedimen Urine",   specimen_type: "Urine Rutin",default_result_type: "qualitative", default_unit: nil },

  # ── FAECES / MIKROBIOLOGI / PATOLOGI ──
  { code: "FAECES",     name: "Faeces Lengkap",              category: "FAECES",        label_group: "Faeces Lengkap",  specimen_type: "Faeces",     default_result_type: "qualitative", default_unit: nil },
  { code: "GRAM",       name: "Pewarnaan Gram",              category: "Mikrobiologi",  label_group: nil,               specimen_type: "Swab",       default_result_type: "qualitative", default_unit: nil },
  { code: "BTA",        name: "Pewarnaan BTA",               category: "Mikrobiologi",  label_group: nil,               specimen_type: "Sputum",     default_result_type: "qualitative", default_unit: nil },
  { code: "KULTUR",     name: "Kultur & Sensitivitas",       category: "Mikrobiologi",  label_group: nil,               specimen_type: "Swab",       default_result_type: "text",        default_unit: nil },
  { code: "KOH",        name: "Pewarnaan Jamur (KOH)",        category: "Mikrobiologi",  label_group: nil,               specimen_type: "Swab",       default_result_type: "qualitative", default_unit: nil },
  { code: "HPA",        name: "Histopatologi (Biopsi)",        category: "Lain-Lain",     label_group: nil,               specimen_type: "Jaringan",   default_result_type: "text",        default_unit: nil },
  { code: "SITOLOGI",   name: "Sitologi Non-Ginekologi",     category: "Lain-Lain",     label_group: nil,               specimen_type: "Sitologi",   default_result_type: "text",        default_unit: nil },
  { code: "FNAB",       name: "Fine Needle Aspiration",        category: "Lain-Lain",     label_group: nil,               specimen_type: "Aspirat",    default_result_type: "text",        default_unit: nil },
  { code: "PAP",        name: "Pap Smear",                   category: "Lain-Lain",     label_group: nil,               specimen_type: "Sekret Serviks", default_result_type: "text",   default_unit: nil },

  # ── Computed source & formula examinations ──
  { code: "LYM#",       name: "Limfosit Absolut",            category: "Hematologi",    label_group: "Darah Lengkap", specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: "10³/µL" },
  { code: "CHOL",       name: "Cholesterol Total",           category: "Kimia Klinik",  label_group: "Profil Lemak",    specimen_type: "Darah Beku", default_result_type: "numeric",     default_unit: "mg/dL" },
  { code: "TG",         name: "Trigliserida",                category: "Kimia Klinik",  label_group: "Profil Lemak",    specimen_type: "Darah Beku", default_result_type: "numeric",     default_unit: "mg/dL" },
  { code: "HDL",        name: "HDL Cholesterol",             category: "Kimia Klinik",  label_group: "Profil Lemak",    specimen_type: "Darah Beku", default_result_type: "numeric",     default_unit: "mg/dL" },
  { code: "TOT_BIL",    name: "Bilirubin Total",             category: "Kimia Klinik",  label_group: "Fungsi Hati",     specimen_type: "Darah Beku", default_result_type: "numeric",     default_unit: "mg/dL" },
  { code: "DIREK_BIL",  name: "Bilirubin Direk",             category: "Kimia Klinik",  label_group: "Fungsi Hati",     specimen_type: "Darah Beku", default_result_type: "numeric",     default_unit: "mg/dL" },
  { code: "NLR",        name: "Neutrophil-Lymphocyte Ratio", category: "Hematologi",    label_group: nil,               specimen_type: "Darah EDTA", default_result_type: "numeric",     default_unit: nil },
  { code: "LDL-CALC",   name: "LDL Cholesterol (Calculated)",category: "Kimia Klinik",  label_group: nil,               specimen_type: "Darah Beku", default_result_type: "numeric",     default_unit: "mg/dL" },
  { code: "CHOL-RATIO", name: "Cholesterol Ratio",          category: "Kimia Klinik",  label_group: nil,               specimen_type: "Darah Beku", default_result_type: "numeric",     default_unit: nil },
  { code: "INDIREK",    name: "Bilirubin Indirek",          category: "Kimia Klinik",  label_group: nil,               specimen_type: "Darah Beku", default_result_type: "numeric",     default_unit: "mg/dL" },
  { code: "GLOB",       name: "Globulin",                   category: "Kimia Klinik",  label_group: nil,               specimen_type: "Darah Beku", default_result_type: "numeric",     default_unit: "g/dL" },
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

# Retire outdated panel codes if present
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

# ── Master Database Form RS Mapped Rules ──
upsert_ref_rule "DL",         name: "Hematologi Lengkap",        result_type: "qualitative", allowed: ["Multi-parameter Panel"], normal: ["Multi-parameter Panel"], loinc: "58410-2"
upsert_ref_rule "IPF",        name: "IPF",                       result_type: "numeric", low: 1.0, high: 5.0, unit: "%", reference_value: "1.0 - 5.0", loinc: "53115-2"
upsert_ref_rule "AEC",        name: "Hitung Eosinofil",          result_type: "numeric", low: 30, high: 350, unit: "/µL", reference_value: "30 - 350", loinc: "711-2"
upsert_ref_rule "BMP",        name: "Gambaran Sumsum Tulang",    result_type: "qualitative", allowed: ["Normoseluler"], normal: ["Normoseluler"], reference_value: "Normoseluler", loinc: "38269-7"
upsert_ref_rule "SIT-KEL",    name: "Sitologi Kelenjar (MGG)",   result_type: "qualitative", allowed: ["Tidak tampak keganasan"], normal: ["Tidak tampak keganasan"], reference_value: "Tidak tampak keganasan", loinc: "33717-0"
upsert_ref_rule "ITRATIO",    name: "IT Ratio",                  result_type: "numeric", high: 0.20, unit: "Rasio", reference_value: "< 0.20", loinc: "30522-7"
upsert_ref_rule "NAP",        name: "Pewarnaan Sitokimia - NAP", result_type: "numeric", low: 20, high: 100, unit: "Score", reference_value: "20 - 100", loinc: "2648-0"

# Hemostasis
upsert_ref_rule "HEMO-PANEL", name: "Hemostasis Lengkap",       result_type: "qualitative", allowed: ["Multi-parameter Panel"], normal: ["Multi-parameter Panel"], loinc: "31032-6"
upsert_ref_rule "BT",         name: "Masa Perdarahan (BT)",      result_type: "numeric", low: 1.0, high: 6.0, unit: "menit", reference_value: "1.0 - 6.0", loinc: "3184-9"
upsert_ref_rule "PT",         name: "Masa Protrombin Plasma",    result_type: "numeric", low: 11.0, high: 15.0, unit: "detik", reference_value: "11.0 - 15.0", loinc: "5902-2"
upsert_ref_rule "APTT",       name: "APTT",                      result_type: "numeric", low: 25.0, high: 35.0, unit: "detik", reference_value: "25.0 - 35.0", loinc: "14979-9"
upsert_ref_rule "TT",         name: "Masa Trombin (TT)",         result_type: "numeric", low: 14.0, high: 19.0, unit: "detik", reference_value: "14.0 - 19.0", loinc: "3243-3"
upsert_ref_rule "FIBRINOGEN", name: "Fibrinogen",                result_type: "numeric", low: 200, high: 400, unit: "mg/dL", reference_value: "200 - 400", loinc: "3255-7"
upsert_ref_rule "D-DIMER",    name: "D-Dimer",                   result_type: "numeric", high: 0.50, unit: "mg/L", reference_value: "< 0.50", loinc: "48065-7"
upsert_ref_rule "ACT",        name: "ACT",                       result_type: "numeric", low: 70, high: 120, unit: "detik", reference_value: "70 - 120", loinc: "3185-6"
upsert_ref_rule "RL",         name: "Rumpell Leede",             result_type: "qualitative", allowed: ["Negatif (< 10 petekie)"], normal: ["Negatif (< 10 petekie)"], reference_value: "Negatif (< 10 petekie)", loinc: "26515-7"
upsert_ref_rule "AGR-PLT",    name: "Agregasi Trombosit",        result_type: "numeric", low: 60, high: 100, unit: "%", reference_value: "60 - 100", loinc: "3202-9"
upsert_ref_rule "VISKOSITAS", name: "Viskositas Darah & Plasma", result_type: "qualitative", reference_value: "Darah: 3.5 - 5.5, Plasma: 1.1 - 1.3", loinc: "33241-1"
upsert_ref_rule "AT3",        name: "AT III",                    result_type: "numeric", low: 80, high: 120, unit: "%", reference_value: "80 - 120", loinc: "27811-9"
upsert_ref_rule "FVIII",      name: "Assay Faktor VIII",         result_type: "numeric", low: 50, high: 150, unit: "%", reference_value: "50 - 150", loinc: "3174-0"
upsert_ref_rule "FIX",        name: "Assay Faktor IX",           result_type: "numeric", low: 50, high: 150, unit: "%", reference_value: "50 - 150", loinc: "3189-8"
upsert_ref_rule "VWF",        name: "vWF Antigen/Activity",      result_type: "numeric", low: 50, high: 150, unit: "%", reference_value: "50 - 150", loinc: "27821-8"

# Hemolitik
upsert_ref_rule "SUGAR-WATER",name: "Sugar Water Test",          result_type: "qualitative", allowed: %w[Positif Negatif], normal: %w[Negatif], abnormal: %w[Positif], loinc: "49020-9"
upsert_ref_rule "HAMSTEST",   name: "Ham's Test",                result_type: "qualitative", allowed: %w[Positif Negatif], normal: %w[Negatif], abnormal: %w[Positif], loinc: "49019-1"
upsert_ref_rule "G6PD",       name: "G6PD Eritrosit",            result_type: "numeric", low: 4.6, high: 13.5, unit: "U/g Hb", reference_value: "4.6 - 13.5", loinc: "2353-1"
upsert_ref_rule "COOMBS-D",   name: "Coombs Test Direk",         result_type: "qualitative", allowed: %w[Positif Negatif], normal: %w[Negatif], abnormal: %w[Positif], loinc: "1007-4"
upsert_ref_rule "COOMBS-I",   name: "Coombs Test Indirek",       result_type: "qualitative", allowed: %w[Positif Negatif], normal: %w[Negatif], abnormal: %w[Positif], loinc: "890-4"
upsert_ref_rule "OFT",        name: "Resistensi Osmotik",        result_type: "qualitative", reference_value: "0.45% - 0.30%", loinc: "2693-0"

# CBC Parameters
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

# LED & Golongan Darah
upsert_ref_rule "LED",    name: "LED (Pria)",            result_type: "numeric", low: 0, high: 15, unit: "mm/jam", reference_value: "0 - 15",  loinc: "4537-7", gender: "male"
upsert_ref_rule "LED",    name: "LED (Wanita)",          result_type: "numeric", low: 0, high: 20, unit: "mm/jam", reference_value: "0 - 20",  loinc: "4537-7", gender: "female"
upsert_ref_rule "GOLDAR", name: "Golongan Darah",        result_type: "qualitative", allowed: %w[A B AB O], normal: %w[A B AB O], loinc: "883-9"
upsert_ref_rule "GOLDAR", name: "Rhesus",                result_type: "qualitative", allowed: ["Positif (+)", "Negatif (-)"], normal: ["Positif (+)"], abnormal: ["Negatif (-)"], loinc: "10331-7"

# Kimia Klinik Rules
upsert_ref_rule "GDS",    name: "GULA DARAH SEWAKTU",    result_type: "numeric", high: 100, unit: "mg/dL", reference_value: "Normal: < 100 | Gangguan Toleransi: 100–126 | Diabetes: > 126", loinc: "1558-6"
upsert_ref_rule "CL",     name: "Chloride (Cl)",         result_type: "numeric", low: 98, high: 107, unit: "mmol/L", reference_value: "98 - 107", loinc: "2075-0"
upsert_ref_rule "K",      name: "Kalium (K)",            result_type: "numeric", low: 3.6, high: 5.2, unit: "mmol/L", reference_value: "3.6 - 5.2", loinc: "2823-3"
upsert_ref_rule "NA",     name: "Natrium (Na)",           result_type: "numeric", low: 135, high: 145, unit: "mmol/L", reference_value: "135 - 145", loinc: "2951-2"
upsert_ref_rule "HBA1C",  name: "HbA1C",                 result_type: "numeric", unit: "%", reference_value: "Diabetes: ≥ 6.5 | Prediabetes: 5.7–6.5 | Target Terapi: < 7.0", loinc: "4548-4"
upsert_ref_rule "LEMAK",  name: "Kolesterol Total",     result_type: "numeric", high: 200, unit: "mg/dL", reference_value: "Diinginkan: < 200 | Batas Atas: 200–240 | Tinggi: ≥ 240", loinc: "2093-3"
upsert_ref_rule "LEMAK",  name: "Kolesterol LDL",       result_type: "numeric", high: 100, unit: "mg/dL", reference_value: "Optimal: < 100 | Batas Atas: 130–160 | Tinggi: ≥ 160", loinc: "13457-7"
upsert_ref_rule "LEMAK",  name: "Kolesterol HDL",       result_type: "numeric", low: 60,   unit: "mg/dL", reference_value: "Optimal: ≥ 60 | Batas: 40–59 | Risiko Tinggi: < 40", loinc: "2085-9"
upsert_ref_rule "LEMAK",  name: "Trigliserida",         result_type: "numeric", high: 150, unit: "mg/dL", reference_value: "Normal: < 150 | Batas Atas: 150–200 | Tinggi: ≥ 200", loinc: "2571-8"
upsert_ref_rule "CRE",    name: "CREATININE (Pria)",     result_type: "numeric", low: 0.7, high: 1.2, unit: "mg/dL", reference_value: "0.7 - 1.2", loinc: "2160-0", gender: "male"
upsert_ref_rule "CRE",    name: "CREATININE (Wanita)",   result_type: "numeric", low: 0.5, high: 1.0, unit: "mg/dL", reference_value: "0.5 - 1.0", loinc: "2160-0", gender: "female"
upsert_ref_rule "UR",     name: "UREUM",                 result_type: "numeric", low: 15,  high: 45,  unit: "mg/dL", reference_value: "15 - 45",   loinc: "3094-0"

# Computed reference rules
upsert_ref_rule "LYM#",      name: "Limfosit Absolut", result_type: "numeric", low: 1.0, high: 4.0,  unit: "10³/µL", reference_value: "1.0 - 4.0"
upsert_ref_rule "CHOL",      name: "Cholesterol",      result_type: "numeric", low: 0,   high: 200,  unit: "mg/dL",   reference_value: "< 200"
upsert_ref_rule "TG",        name: "Trigliserida",     result_type: "numeric", low: 0,   high: 150,  unit: "mg/dL",   reference_value: "< 150"
upsert_ref_rule "HDL",       name: "HDL",              result_type: "numeric", low: 40,  high: 999,  unit: "mg/dL",   reference_value: "> 40"
upsert_ref_rule "TOT_BIL",   name: "Bilirubin Total",  result_type: "numeric", low: 0.0, high: 1.2,  unit: "mg/dL",   reference_value: "0.0 - 1.2"
upsert_ref_rule "DIREK_BIL", name: "Bilirubin Direk",  result_type: "numeric", low: 0.0, high: 0.3,  unit: "mg/dL",   reference_value: "0.0 - 0.3"

upsert_ref_rule "NLR",        name: "NLR",              result_type: "numeric", low: 1.0,  high: 3.0, reference_value: "1.0 - 3.0",
                             formula_expression: "NEU# / LYM#",          formula_inputs: [{ "code" => "NEU#" }, { "code" => "LYM#" }]
upsert_ref_rule "LDL-CALC",   name: "LDL Cholesterol",  result_type: "numeric", low: 0,    high: 100, unit: "mg/dL", reference_value: "< 100",
                             formula_expression: "CHOL - (TG / 5) - HDL", formula_inputs: [{ "code" => "CHOL" }, { "code" => "TG" }, { "code" => "HDL" }]
upsert_ref_rule "CHOL-RATIO", name: "Cholesterol Ratio",result_type: "numeric", low: 0,    high: 5,   reference_value: "< 5",
                             formula_expression: "CHOL / HDL",            formula_inputs: [{ "code" => "CHOL" }, { "code" => "HDL" }]
upsert_ref_rule "INDIREK",    name: "Bilirubin Indirek",result_type: "numeric", low: 0.0,  high: 1.1, unit: "mg/dL", reference_value: "0.0 - 1.1",
                             formula_expression: "TOT_BIL - DIREK_BIL",   formula_inputs: [{ "code" => "TOT_BIL" }, { "code" => "DIREK_BIL" }]
upsert_ref_rule "GLOB",       name: "Globulin",         result_type: "numeric", low: 2.0,  high: 3.5, unit: "g/dL", reference_value: "2.0 - 3.5",
                             formula_expression: "TP - ALB",              formula_inputs: [{ "code" => "TP" }, { "code" => "ALB" }], loinc: "2336-6"

puts "  ✅ #{ReferenceRule.count} reference rules seeded"

# ─── Sample Specimens & Works ─────────────────────────────────────────────────

puts "🧪 Creating sample specimens..."

if Specimen.count < 5
  exam_ids_for = lambda do |codes|
    exams = Examination.where(code: codes).index_by(&:code)
    codes.map { |code| exams.fetch(code).id }
  end

  darah_lengkap_ids = exam_ids_for.call(darah_lengkap_codes)
  elektrolit_ids    = exam_ids_for.call(elektrolit_codes)
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

  sample_results = {
    "RDW-CV" => [
      { exam: "RDW-CV", ref: "RDW-CV",              val: "11.8", unit: "%" },
      { exam: "RDW-SD", ref: "RDW-SD",              val: "42",   unit: "fL" },
      { exam: "MONO",   ref: "Monosit",             val: "8.4",  unit: "%" },
      { exam: "LYMPH",  ref: "Limfosit",            val: "34.6", unit: "%" },
      { exam: "SEG",    ref: "Segmen",              val: "49.5", unit: "%" },
      { exam: "BAND",   ref: "Batang",              val: "2.0",  unit: "%" },
      { exam: "EOS",    ref: "Eosinofil",           val: "7.0",  unit: "%" },
      { exam: "BASO",   ref: "Basofil",             val: "0.5",  unit: "%" },
      { exam: "MCHC",   ref: "MCHC",                val: "34",   unit: "g/dL" },
      { exam: "MCH",    ref: "MCH",                 val: "27",   unit: "pg" },
      { exam: "MCV",    ref: "MCV",                 val: "82",   unit: "fL" },
      { exam: "RBC",    ref: "ERITROSIT (Pria)",    val: "5.58", unit: "10⁶/µL" },
      { exam: "PLT",    ref: "Trombosit",           val: "333",  unit: "10³/µL" },
      { exam: "HCT",    ref: "Hematokrit (Pria)",   val: "45.5", unit: "%" },
      { exam: "WBC",    ref: "Lekosit",             val: "7.6",  unit: "10³/µL" },
      { exam: "HGB",    ref: "Hemoglobin (Pria)",   val: "15.3", unit: "g/dL" },
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
      { ref: "Kolesterol Total", val: "211", unit: "mg/dL" },
      { ref: "Kolesterol LDL",   val: "155", unit: "mg/dL" },
      { ref: "Kolesterol HDL",   val: "38",  unit: "mg/dL" },
      { ref: "Trigliserida",     val: "91",  unit: "mg/dL" },
    ],
    "HBA1C" => [
      { ref: "HbA1C", val: "5.4", unit: "%" },
    ],
    "HIV" => [
      { ref: "Anti HIV", val: "Non Reaktif", unit: nil },
    ],
  }

  sample_results.each do |exam_code, rows|
    work = Work.joins(:examination).where(examinations: { code: exam_code })
               .where(status: %w[pending validated]).order(created_at: :desc).first
    next unless work

    exam = Examination.find_by!(code: exam_code)

    rows.each do |row|
      ref_exam = row[:exam] ? Examination.find_by!(code: row[:exam]) : exam
      ref_rule = ReferenceRule.find_by(examination: ref_exam, name: row[:ref])
      next unless ref_rule

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
