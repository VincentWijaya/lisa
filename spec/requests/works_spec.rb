require "rails_helper"

RSpec.describe "Works", type: :request do
  let!(:user) { create(:user, email: "user@lisa.local", password: "Password@123", active: true) }
  let(:examination) { create(:examination, default_unit: "mg/dL") }
  let(:work) { create(:work, examination: examination, status: "validated", test_codes_text: "#{examination.code};") }
  let!(:reference_rule) { create(:reference_rule, examination: examination, name: "Glucose", unit: "mg/dL") }

  before do
    post session_path, params: { email: user.email, password: "Password@123" }
  end

  describe "GET /works/:id" do
    it "renders a bulk result form for reference rules" do
      existing_result = create(:examination_result, work: work, reference_rule: reference_rule, result_value: "5.1", result_unit: "mg/dL")

      get work_path(work)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(upsert_results_work_path(work))
      expect(response.body).to include("Glucose")
      expect(response.body).to include(existing_result.result_value)
      expect(response.body).not_to include("Edit")
      expect(response.body).not_to include("Hapus")
      expect(response.body).to include("Verifikasi")
    end
  end

  describe "POST /works/:id/upsert_results" do
    it "saves result rows through the bulk form payload" do
      post upsert_results_work_path(work), params: {
        examination_results: {
          results: {
            reference_rule.id.to_s => {
              reference_rule_id: reference_rule.id,
              result_value: "5.2",
              result_unit: "",
              source: "instrument"
            }
          }
        }
      }

      expect(response).to redirect_to(work_path(work))
      result = work.examination_results.find_by!(reference_rule: reference_rule)
      expect(result.result_value).to eq("5.2")
      expect(result.result_unit).to eq("mg/dL")
      expect(result.source).to eq("instrument")
    end
  end
end
