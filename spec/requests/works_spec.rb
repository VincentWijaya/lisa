require "rails_helper"

RSpec.describe "Works", type: :request do
  let!(:user) { create(:user, email: "user@lisa.local", password: "Password@123", active: true) }
  let(:examination) { create(:examination, default_unit: "mg/dL") }
  let(:work) { create(:work, examination: examination, status: "validated", verified_at: Time.current, test_codes_text: "#{examination.code};") }
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
      expect(response.body).to include("Validasi")
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

  describe "PATCH /works/:id/verify_all_results" do
    it "verifies all unverified results on the work" do
      result_a = create(:examination_result, work: work, reference_rule: reference_rule, result_value: "5.1", verified_at: nil)
      result_b = create(:examination_result, work: work, reference_rule: reference_rule, result_value: "6.2", verified_at: nil)

      patch verify_all_results_work_path(work)

      expect(response).to redirect_to(work_path(work))
      expect(result_a.reload.verified_at).not_to be_nil
      expect(result_b.reload.verified_at).not_to be_nil
      expect(result_a.reload.verified_by).to eq(user.id)
      expect(result_b.reload.verified_by).to eq(user.id)
    end

    it "alerts when there are no unverified results" do
      create(:examination_result, work: work, reference_rule: reference_rule, result_value: "5.1", verified_at: Time.current)

      patch verify_all_results_work_path(work)

      expect(response).to redirect_to(work_path(work))
      follow_redirect!
      expect(response.body).to include(I18n.t("works.flash.no_results_to_verify"))
    end
  end

  describe "GET /works (index)" do
    let!(:specimen_a) { create(:specimen, patient_name: "Marjolaine Landing", patient_id: "P-10005", medical_record_id: "RM-2004-005", order_number: "2606090095") }
    let!(:specimen_b) { create(:specimen, patient_name: "Budi Santoso",       patient_id: "P-20007", medical_record_id: "RM-2004-099", order_number: "2606090099") }
    let!(:work_a)     { create(:work, specimen: specimen_a, barcode_id: "2606090095-01", status: "pending") }
    let!(:work_b)     { create(:work, specimen: specimen_b, barcode_id: "2606090099-01", status: "validated") }

    it "renders the Figma-style page chrome" do
      get works_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("works.index.title"))
      expect(response.body).to include('id="works_list"')
      expect(response.body).to include('change-&gt;auto-submit#change')
    end

    it "filters by exact q (no LIKE)" do
      get works_path, params: { q: "2606090095-01" }

      expect(response.body).to include("2606090095-01")
      expect(response.body).not_to include("2606090099-01")
    end

    it "filters by status exactly without LIKE" do
      get works_path, params: { status: "validated" }

      expect(response.body).to include("2606090099-01")
      expect(response.body).not_to include("2606090095-01")
    end

    it "ignores partial queries (no substring matching)" do
      get works_path, params: { q: "2606" }

      expect(response.body).not_to include("2606090095-01")
      expect(response.body).not_to include("2606090099-01")
    end
  end
end
