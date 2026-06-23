require "rails_helper"

RSpec.describe "Api::V1::Examinations", type: :request do
  describe "GET /api/v1/examinations" do
    let!(:exam_a) { create(:examination, code: "CBC", name: "CBC", category: "HEMATOLOGI", status: "active") }
    let!(:exam_b) { create(:examination, code: "GLU", name: "Glucose", category: "KIMIA KLINIK", status: "active") }
    let!(:exam_c) { create(:examination, code: "RET", name: "Retired", category: "OTHER", status: "inactive") }

    it "returns all examinations ordered by name" do
      get "/api/v1/examinations", as: :json

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["data"].size).to eq(3)
      expect(body["data"].first["code"]).to eq("CBC")
      expect(body["data"].second["code"]).to eq("GLU")
    end

    it "returns camelCase JSON keys" do
      get "/api/v1/examinations", as: :json

      exam = response.parsed_body["data"].first
      expect(exam).to include("code", "name", "category", "labelGroup", "specimenType", "defaultResultType", "defaultUnit", "status")
    end

    it "includes pagination metadata" do
      get "/api/v1/examinations", as: :json

      expect(response.parsed_body["pagination"]).to include("page", "limit")
    end

    it "respects limit parameter" do
      get "/api/v1/examinations", params: { limit: 1 }, as: :json

      expect(response.parsed_body["data"].size).to eq(1)
    end

    it "returns empty array when no examinations exist" do
      Examination.delete_all

      get "/api/v1/examinations", as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]).to eq([])
    end
  end
end
