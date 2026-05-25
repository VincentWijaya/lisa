require "rails_helper"

RSpec.describe "Api::V1::Specimens", type: :request do
  describe "POST /api/v1/specimens" do
    let!(:examination) { create(:examination, code: "CBC") }

    it "creates a specimen with works" do
      post "/api/v1/specimens", params: {
        patient_id: "12345",
        patient_name: "Jane Doe",
        birth_date: "1990-05-15",
        gender: "Female",
        medical_record_id: "MR-2026-0001",
        lab_id: "LAB123",
        department: "ER",
        collection_datetime: "2026-05-25T10:30:00Z",
        examination_ids: [examination.id]
      }, as: :json

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["patientId"]).to eq("12345")
      expect(body["works"].size).to eq(1)
      expect(body["works"].first["barcodeId"]).to end_with("-01")
    end

    it "returns validation errors" do
      post "/api/v1/specimens", params: {
        patient_name: "Jane Doe",
        birth_date: "1990-05-15",
        gender: "Female",
        lab_id: "LAB123",
        examination_ids: [99_999]
      }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["errors"]).to include("Examination 99999 not found or inactive")
    end
  end
end
