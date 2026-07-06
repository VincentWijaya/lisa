require "rails_helper"

RSpec.describe ExaminationResults::ComputedResultRecomputer do
  let(:specimen) do
    create(:specimen,
      lab_id: "LAB-1",
      patient_id: "P1",
      medical_record_id: "MR1",
      gender: "male",
      collection_datetime: Time.current
    )
  end
  let(:user) { create(:user) }

  let(:neu_exam)      { Examination.create!(code: "NEU#",     name: "NEU Abs",   category: "HEMATOLOGI",   specimen_type: "Darah EDTA", status: "active", default_result_type: "numeric", default_unit: "10^3/uL") }
  let(:lym_exam)      { Examination.create!(code: "LYM#",     name: "LYM Abs",   category: "HEMATOLOGI",   specimen_type: "Darah EDTA", status: "active", default_result_type: "numeric", default_unit: "10^3/uL") }
  let(:chol_exam)     { Examination.create!(code: "CHOL",     name: "Cholesterol", category: "KIMIA KLINIK", specimen_type: "Darah Beku", status: "active", default_result_type: "numeric", default_unit: "mg/dL") }
  let(:tg_exam)       { Examination.create!(code: "TG",       name: "Trigliserida", category: "KIMIA KLINIK", specimen_type: "Darah Beku", status: "active", default_result_type: "numeric", default_unit: "mg/dL") }
  let(:hdl_exam)      { Examination.create!(code: "HDL",      name: "HDL",         category: "KIMIA KLINIK", specimen_type: "Darah Beku", status: "active", default_result_type: "numeric", default_unit: "mg/dL") }
  let(:tot_bil_exam)  { Examination.create!(code: "TOT_BIL",  name: "Tot Bil",     category: "KIMIA KLINIK", specimen_type: "Darah Beku", status: "active", default_result_type: "numeric", default_unit: "mg/dL") }
  let(:direk_bil_exam){ Examination.create!(code: "DIREK_BIL",name: "Direk Bil",   category: "KIMIA KLINIK", specimen_type: "Darah Beku", status: "active", default_result_type: "numeric", default_unit: "mg/dL") }
  let(:tp_exam)       { Examination.create!(code: "TP",       name: "TP",          category: "KIMIA KLINIK", specimen_type: "Darah Beku", status: "active", default_result_type: "numeric", default_unit: "g/dL") }
  let(:alb_exam)      { Examination.create!(code: "ALB",      name: "ALB",         category: "KIMIA KLINIK", specimen_type: "Darah Beku", status: "active", default_result_type: "numeric", default_unit: "g/dL") }

  let(:nlr_exam)        { Examination.create!(code: "NLR",        name: "NLR",   category: "HEMATOLOGI",   specimen_type: "Darah EDTA", status: "active", default_result_type: "numeric") }
  let(:ldl_exam)        { Examination.create!(code: "LDL-CALC",   name: "LDL",   category: "KIMIA KLINIK", specimen_type: "Darah Beku",  status: "active", default_result_type: "numeric", default_unit: "mg/dL") }
  let(:chol_ratio_exam) { Examination.create!(code: "CHOL-RATIO", name: "Ratio", category: "KIMIA KLINIK", specimen_type: "Darah Beku",  status: "active", default_result_type: "numeric") }
  let(:indirek_exam)    { Examination.create!(code: "INDIREK",    name: "Indirek", category: "KIMIA KLINIK", specimen_type: "Darah Beku", status: "active", default_result_type: "numeric", default_unit: "mg/dL") }
  let(:glob_exam)       { Examination.create!(code: "GLOB",       name: "Glob",   category: "KIMIA KLINIK", specimen_type: "Darah Beku",  status: "active", default_result_type: "numeric", default_unit: "g/dL") }

  before do
    neu_exam; lym_exam; chol_exam; tg_exam; hdl_exam; tot_bil_exam; direk_bil_exam; tp_exam; alb_exam
    nlr_exam; ldl_exam; chol_ratio_exam; indirek_exam; glob_exam

    create(:reference_rule, examination: neu_exam,      name: "NEU#",     result_type: "numeric")
    create(:reference_rule, examination: lym_exam,      name: "LYM#",     result_type: "numeric")
    create(:reference_rule, examination: chol_exam,     name: "CHOL",     result_type: "numeric")
    create(:reference_rule, examination: tg_exam,       name: "TG",       result_type: "numeric")
    create(:reference_rule, examination: hdl_exam,      name: "HDL",      result_type: "numeric")
    create(:reference_rule, examination: tot_bil_exam,  name: "TOT_BIL",  result_type: "numeric")
    create(:reference_rule, examination: direk_bil_exam,name: "DIREK_BIL",result_type: "numeric")
    create(:reference_rule, examination: tp_exam,       name: "TP",       result_type: "numeric")
    create(:reference_rule, examination: alb_exam,      name: "ALB",      result_type: "numeric")

    create(:reference_rule, examination: nlr_exam,        name: "NLR",   result_type: "numeric", formula_expression: "NEU# / LYM#",     formula_inputs: [{ "code" => "NEU#" }, { "code" => "LYM#" }])
    create(:reference_rule, examination: ldl_exam,        name: "LDL",   result_type: "numeric", formula_expression: "CHOL - (TG / 5) - HDL", formula_inputs: [{ "code" => "CHOL" }, { "code" => "TG" }, { "code" => "HDL" }])
    create(:reference_rule, examination: chol_ratio_exam, name: "Ratio", result_type: "numeric", formula_expression: "CHOL / HDL",          formula_inputs: [{ "code" => "CHOL" }, { "code" => "HDL" }])
    create(:reference_rule, examination: indirek_exam,    name: "Indir", result_type: "numeric", formula_expression: "TOT_BIL - DIREK_BIL", formula_inputs: [{ "code" => "TOT_BIL" }, { "code" => "DIREK_BIL" }])
    create(:reference_rule, examination: glob_exam,       name: "Glob",  result_type: "numeric", formula_expression: "TP - ALB",            formula_inputs: [{ "code" => "TP" }, { "code" => "ALB" }])
  end

  let(:counter) { { n: 0 } }

  def work_for(exam, label_sequence: 1)
    create(:work, specimen: specimen, examination: exam, label_sequence: label_sequence, barcode_id: "#{specimen.order_number}-#{format('%02d', label_sequence)}")
  end

  def save_source(code, value, label_sequence: nil)
    exam = Examination.find_by!(code: code)
    rule = exam.reference_rules.active.first
    seq = label_sequence || (counter[:n] += 1)
    work = work_for(exam, label_sequence: seq)
    ExaminationResult.create!(work: work, reference_rule: rule, result_value: value, source: "manual")
  end

  it "is a no-op when no source results are present" do
    result = described_class.call(specimen: specimen, entered_by: user)
    expect(result).to be_success
    expect(result.updated).to eq(0)
  end

  it "computes all five formulas when all source results are present" do
    save_source("NEU#", 5.0)
    save_source("LYM#", 2.0)
    save_source("CHOL", 200.0)
    save_source("TG", 150.0)
    save_source("HDL", 50.0)
    save_source("TOT_BIL", 1.2)
    save_source("DIREK_BIL", 0.4)
    save_source("TP", 7.5)
    save_source("ALB", 4.2)

    result = described_class.call(specimen: specimen, entered_by: user)
    expect(result).to be_success
    expect(result.updated).to eq(5)

    expected = { "NLR" => 2.5, "LDL-CALC" => 120.0, "CHOL-RATIO" => 4.0, "INDIREK" => 0.8, "GLOB" => 3.3 }
    expected.each do |code, value|
      rule = Examination.find_by!(code: code).reference_rules.active.first
      rec = ExaminationResult.where(reference_rule_id: rule.id, work: specimen.works).last
      expect(rec.result_value.to_f).to eq(value), "#{code} expected #{value}, got #{rec.result_value}"
    end
  end

  it "updates an existing computed result when a source value changes" do
    save_source("TP", 8.0)
    save_source("ALB", 4.0)
    described_class.call(specimen: specimen, entered_by: user)
    glob_rule = Examination.find_by!(code: "GLOB").reference_rules.active.first
    first = ExaminationResult.where(reference_rule_id: glob_rule.id, work: specimen.works).last
    expect(first.result_value.to_f).to eq(4.0)

    tp_rule = Examination.find_by!(code: "TP").reference_rules.active.first
    ExaminationResult.where(work: specimen.works, reference_rule_id: tp_rule.id).update_all(result_value: "9.0")
    described_class.call(specimen: specimen, entered_by: user)

    second = ExaminationResult.where(reference_rule_id: glob_rule.id, work: specimen.works).last
    expect(second.id).to eq(first.id)
    expect(second.result_value.to_f).to eq(5.0)
  end

  it "is idempotent when recomputed twice" do
    save_source("TP", 7.0)
    save_source("ALB", 4.0)
    described_class.call(specimen: specimen, entered_by: user)
    described_class.call(specimen: specimen, entered_by: user)
    glob_rule = Examination.find_by!(code: "GLOB").reference_rules.active.first
    expect(ExaminationResult.where(reference_rule_id: glob_rule.id, work: specimen.works).count).to eq(1)
  end

  it "skips a formula when only some inputs are available" do
    save_source("TP", 7.0)
    result = described_class.call(specimen: specimen, entered_by: user)
    expect(result).to be_success
    expect(result.updated).to eq(0)
  end
end
