require "rails_helper"

RSpec.describe "Api::V1::Works", type: :request do
  let!(:examination) { create(:examination, code: "CHEM") }
  let!(:secondary_examination) { create(:examination, code: "UREA") }
  let!(:specimen) { create(:specimen) }
  let!(:work) { create(:work, specimen: specimen, examination: examination, barcode_id: "2605250001-01", label_sequence: 1, test_codes_text: "CHEM;") }
  let!(:secondary_work) { create(:work, specimen: specimen, examination: secondary_examination, barcode_id: "2605250001-02", label_sequence: 2, test_codes_text: "UREA;") }
  let!(:reference_rule) { create(:reference_rule, examination: examination, numeric_low_value: 4.0, numeric_high_value: 6.0, unit: "g/dL") }

  describe "POST /api/v1/works/:id/results" do
    it "creates an examination result" do
      post "/api/v1/works/#{work.id}/results", params: {
        result_value: "5.1",
        reference_rule_id: reference_rule.id,
        source: "manual"
      }, as: :json

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["workId"]).to eq(work.id)
      expect(body["interpretation"]).to eq("normal")
    end
  end

  describe "PATCH /api/v1/works/:id/validate" do
    it "moves the work into the first transition and stores the verification timestamp" do
      patch "/api/v1/works/#{work.id}/validate", as: :json

      expect(response).to have_http_status(:ok)
      expect(work.reload.status).to eq("validated")
      expect(work.verified_at).to be_present
      expect(work.validated_at).to be_nil
    end
  end

  describe "PATCH /api/v1/works/:id/cancel" do
    it "cancels the work" do
      patch "/api/v1/works/#{secondary_work.id}/cancel", as: :json

      expect(response).to have_http_status(:ok)
      expect(secondary_work.reload.status).to eq("cancelled")
    end
  end

  describe "PATCH /api/v1/works/:id/verify" do
    it "moves the work into the final transition, stores the validation timestamp, and auto-completes the specimen" do
      work.update!(status: "validated", verified_at: Time.current)
      secondary_work.update!(status: "cancelled", cancelled_at: Time.current)

      patch "/api/v1/works/#{work.id}/verify", as: :json

      expect(response).to have_http_status(:ok)
      expect(work.reload.status).to eq("verified")
      expect(work.validated_at).to be_present
      expect(specimen.reload.status).to eq("complete")
      expect(specimen.completion_datetime).to be_present
    end
  end
end
