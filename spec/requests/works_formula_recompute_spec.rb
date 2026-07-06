require "rails_helper"

RSpec.describe "Works - formula recompute on web form", type: :request do
  let!(:user) { create(:user, email: "user@lisa.local", password: "Password@123", active: true) }
  let(:specimen) do
    create(:specimen,
      lab_id: "LAB-1",
      patient_id: "P1",
      medical_record_id: "MR1",
      gender: "male",
      collection_datetime: Time.current
    )
  end

  let(:neu_exam)  { Examination.create!(code: "NEU#", name: "NEU Abs", category: "HEMATOLOGI", specimen_type: "Darah EDTA", status: "active", default_result_type: "numeric", default_unit: "10^3/uL") }
  let(:lym_exam)  { Examination.create!(code: "LYM#", name: "LYM Abs", category: "HEMATOLOGI", specimen_type: "Darah EDTA", status: "active", default_result_type: "numeric", default_unit: "10^3/uL") }
  let(:nlr_exam)  { Examination.create!(code: "NLR",   name: "NLR",     category: "HEMATOLOGI", specimen_type: "Darah EDTA", status: "active", default_result_type: "numeric") }

  let!(:neu_rule) { create(:reference_rule, examination: neu_exam, name: "NEU#", unit: "10^3/uL", result_type: "numeric") }
  let!(:lym_rule) { create(:reference_rule, examination: lym_exam, name: "LYM#", unit: "10^3/uL", result_type: "numeric") }
  let!(:nlr_rule) { create(:reference_rule, examination: nlr_exam, name: "NLR", result_type: "numeric", formula_expression: "NEU# / LYM#", formula_inputs: [{ "code" => "NEU#" }, { "code" => "LYM#" }]) }

  let(:neu_work) { create(:work, specimen: specimen, examination: neu_exam, label_sequence: 1, barcode_id: "#{specimen.order_number}-01") }
  let(:nlr_work) { create(:work, specimen: specimen, examination: nlr_exam, label_sequence: 2, barcode_id: "#{specimen.order_number}-02") }

  before do
    post session_path, params: { email: user.email, password: "Password@123" }
  end

  it "recomputes formulas for the specimen when source results are saved via the web form" do
    ExaminationResult.create!(work: neu_work, reference_rule: neu_rule, result_value: "5.0", result_unit: "10^3/uL", source: "manual")
    ExaminationResult.create!(work: neu_work, reference_rule: lym_rule, result_value: "2.0", result_unit: "10^3/uL", source: "manual")

    post upsert_results_work_path(neu_work), params: {
      examination_results: {
        results: {
          neu_rule.id.to_s => {
            reference_rule_id: neu_rule.id,
            result_value: "6.0",
            result_unit: ""
          }
        }
      }
    }

    expect(response).to redirect_to(work_path(neu_work))

    nlr_result = ExaminationResult.where(work: specimen.works, reference_rule: nlr_rule).last
    expect(nlr_result).not_to be_nil
    expect(nlr_result.result_value.to_f).to eq(3.0)
  end
end
