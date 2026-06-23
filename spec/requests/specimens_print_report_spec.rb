require "rails_helper"

RSpec.describe "Specimens print report", type: :request do
  let!(:user) { create(:user, email: "user@lisa.local", password: "Password@123", active: true) }
  let(:specimen)   { create(:specimen, patient_id: "P-1001", gender: "Laki-laki", status: "in_progress") }
  let(:examination) { create(:examination, code: "GLU", category: "KIMIA KLINIK", default_unit: "mg/dL", default_result_type: "numeric") }
  let!(:work) do
    create(:work, specimen: specimen, examination: examination, status: "validated",
                  verified_at: Time.current, test_codes_text: "GLU;")
  end
  let!(:unisex_rule) { create(:reference_rule, examination: examination, name: "Glucose", unit: "mg/dL", gender: nil,
                                numeric_low_value: 70, numeric_high_value: 110) }
  let!(:male_rule)    { create(:reference_rule, examination: examination, name: "Glucose (Pria)", unit: "mg/dL", gender: "male",
                                numeric_low_value: 70, numeric_high_value: 110) }
  let!(:female_rule)  { create(:reference_rule, examination: examination, name: "Glucose (Wanita)", unit: "mg/dL", gender: "female",
                                numeric_low_value: 70, numeric_high_value: 110) }

  before do
    post session_path, params: { email: user.email, password: "Password@123" }
  end

  it "renders 200 for the print report" do
    get print_report_specimen_path(specimen)
    expect(response).to have_http_status(:ok)
  end

  it "shows only the latest non-empty result for a rule" do
    rule = unisex_rule
    create(:examination_result, work: work, reference_rule: rule, result_value: "5.1", source: "manual")
    create(:examination_result, work: work, reference_rule: rule, result_value: "9.9", source: "manual")

    get print_report_specimen_path(specimen)
    expect(response.body).to include("9.9")
    expect(response.body).not_to include(">5.1<")
  end

  it "hides work rows when there are no results with values" do
    create(:examination_result, work: work, reference_rule: unisex_rule, result_value: "5.1", source: "manual")
    empty_work_exam = create(:examination, code: "EMPTY", category: "KIMIA KLINIK", default_unit: nil, default_result_type: "qualitative")
    empty_work = create(:work, specimen: specimen, examination: empty_work_exam, status: "validated",
                        verified_at: Time.current, test_codes_text: "EMPTY;", label_sequence: 2)
    empty_rule = create(:reference_rule, examination: empty_work_exam, name: "No Result", result_type: "qualitative")
    # No examination_result created for empty_work — the work has zero results.

    get print_report_specimen_path(specimen)
    expect(response.body).to include("Glucose")
    expect(response.body).not_to include("No Result")
    expect(response.body).not_to include("Belum ada hasil")
    expect(response.body).not_to include(empty_work.examination.name)
  end

  it "only renders rules matching the specimen gender" do
    create(:examination_result, work: work, reference_rule: male_rule,   result_value: "M-VAL", source: "manual")
    create(:examination_result, work: work, reference_rule: female_rule, result_value: "F-VAL", source: "manual")

    get print_report_specimen_path(specimen)
    expect(response.body).to include("M-VAL")
    expect(response.body).to include("Glucose (Pria)")
    expect(response.body).not_to include("F-VAL")
    expect(response.body).not_to include("Glucose (Wanita)")
  end

  it "hides categories whose works have no results" do
    create(:examination_result, work: work, reference_rule: unisex_rule, result_value: "5.1", source: "manual")
    other_exam = create(:examination, code: "OTHER", category: "HEMATOLOGI", default_unit: nil, default_result_type: "qualitative")
    create(:work, specimen: specimen, examination: other_exam, status: "validated",
                  verified_at: Time.current, test_codes_text: "OTHER;", label_sequence: 2)
    other_rule = create(:reference_rule, examination: other_exam, name: "Other Test", result_type: "qualitative")

    get print_report_specimen_path(specimen)
    expect(response.body).to include("KIMIA KLINIK")
    expect(response.body).not_to include("HEMATOLOGI")
    expect(response.body).not_to include("Other Test")
  end
end
