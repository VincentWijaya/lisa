require "rails_helper"

RSpec.describe "POST /api/v1/analyzer/results" do
  let(:specimen) { create(:specimen, patient_id: "1234", status: "pending") }
  let(:examination) { create(:examination, code: "WBC-PANEL") }
  let!(:work) { create(:work, specimen: specimen, examination: examination, status: "pending") }
  let!(:reference_rule) do
    create(:reference_rule, examination: examination, loinc_code: "6690-2",
           name: "WBC", result_type: "numeric", numeric_low_value: 4.0, numeric_high_value: 10.0)
  end

  let(:payload) do
    {
      patient_id: "1234",
      gender: "Female",
      message_datetime: "20260316150051",
      message_control_id: "3",
      results: [
        { loinc: "6690-2", local_code: nil, test_name: "WBC",
          value: 7.59, unit: "10*3/uL", reference_range: "4.00-10.00", flag: "N" },
        { loinc: nil, local_code: "08001", test_name: "Take Mode",
          value: "O", unit: "", reference_range: "", flag: "" }
      ]
    }
  end

  let(:json) { JSON.parse(response.body) }

  def post_results(body = payload)
    post "/api/v1/analyzer/results",
         params: body.to_json,
         headers: { "Content-Type" => "application/json" }
  end

  it "returns 201" do
    post_results
    expect(response).to have_http_status(:created)
  end

  it "creates examination results for matched entries" do
    expect { post_results }.to change(ExaminationResult, :count).by(1)
  end

  it "returns processed/created/skipped counts" do
    post_results
    expect(json["processed"]).to eq(2)
    expect(json["created"]).to eq(1)
    expect(json["skipped"]).to eq(1)
  end

  it "includes serialized results in response" do
    post_results
    expect(json["results"]).to be_an(Array)
    expect(json["results"].first["resultValue"]).to eq("7.59")
    expect(json["results"].first["workId"]).to eq(work.id)
  end

  context "when patient is not found" do
    let(:payload) { super().merge(patient_id: "NOTFOUND") }

    it "returns 422" do
      post_results
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns error messages" do
      post_results
      expect(json["errors"]).to be_present
    end
  end

  context "when multiple active specimens exist for patient" do
    before { create(:specimen, patient_id: "1234", status: "pending") }

    it "returns 422" do
      post_results
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "returns descriptive error" do
      post_results
      expect(json["errors"]).to include(match(/Multiple active specimens found/))
    end
  end
end
