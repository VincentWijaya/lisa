require "rails_helper"

RSpec.describe "Specimens manual input", type: :request do
  let!(:user) { create(:user, email: "tech@lisa.local", password: "Password@123", active: true) }
  let!(:examination_a) { create(:examination, code: "GLU", category: "KIMIA KLINIK", default_result_type: "numeric", default_unit: "mg/dL") }
  let!(:examination_b) { create(:examination, code: "HGB", category: "HEMATOLOGI", default_result_type: "numeric", default_unit: "g/dL") }
  let!(:examination_c) { create(:examination, code: "WBC", category: "HEMATOLOGI", default_result_type: "numeric", default_unit: "10^3/µL", label_group: "Darah Lengkap") }
  let!(:inactive_exam) { create(:examination, code: "RETIRED", status: "inactive", default_result_type: "qualitative") }

  before do
    post session_path, params: { email: user.email, password: "Password@123" }
  end

  describe "GET /specimens/new" do
    it "renders the new specimen form" do
      get new_specimen_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Spesimen Baru")
      expect(response.body).to include(examination_a.name)
      expect(response.body).to include(examination_c.name)
      expect(response.body).not_to include(inactive_exam.name)
    end

    it "groups examinations by category" do
      get new_specimen_path
      expect(response.body).to include("KIMIA KLINIK")
      expect(response.body).to include("HEMATOLOGI")
    end

    it "renders the redesigned layout (kembali, breadcrumb, section bars, search, per-category select-all)" do
      get new_specimen_path
      expect(response.body).to include(I18n.t("specimens.new.back"))
      expect(response.body).to include(I18n.t("specimens.new.breadcrumb.specimens"))
      expect(response.body).to include(I18n.t("specimens.new.breadcrumb.current"))
      expect(response.body).to include(I18n.t("specimens.new.patient_section"))
      expect(response.body).to include(CGI.escapeHTML(I18n.t("specimens.new.collection_section")))
      expect(response.body).to include(I18n.t("specimens.new.works_section"))
      expect(response.body).to include(I18n.t("specimens.new.options_section"))
      expect(response.body).to include(I18n.t("specimens.new.search_placeholder"))
      expect(response.body).to include(I18n.t("specimens.new.select_label_groups"))
      expect(response.body).to include('data-examination-picker-target="categorySelectAll"')
    end

    it "renders patient_id as an inputable field" do
      get new_specimen_path
      expect(response.body).not_to match(/<input[^>]*name="specimen\[patient_id\]"[^>]*disabled/)
      expect(response.body).to include('name="specimen[patient_id]"')
    end
  end

  describe "POST /specimens" do
    let(:valid_params) do
      {
        specimen: {
          patient_id:          "P-NEW-001",
          patient_name:        "Andi Wijaya",
          birth_date:          "1990-05-15",
          gender:              "Laki-laki",
          medical_record_id:   "RM-2026-001",
          lab_id:              "LAB-01",
          department:          "Penyakit Dalam",
          collection_datetime: "2026-07-10T08:30",
          referring_doctor:    "dr. Test, Sp.PD",
          examination_ids:     [ examination_a.id, examination_b.id, examination_c.id ]
        }
      }
    end

    it "creates a specimen with all selected works" do
      expect {
        post specimens_path, params: valid_params
      }.to change(Specimen, :count).by(1)
         .and change(Work, :count).by(3)

      specimen = Specimen.last
      expect(specimen.patient_name).to eq("Andi Wijaya")
      expect(specimen.works.count).to eq(3)
      expect(specimen.works.pluck(:examination_id)).to contain_exactly(examination_a.id, examination_b.id, examination_c.id)
    end

    it "groups examinations sharing a label_group into one work" do
      post specimens_path, params: valid_params
      specimen = Specimen.last
      grouped_work = specimen.works.find_by(examination: examination_c)
      expect(grouped_work.test_codes_text).to include(examination_c.code)
    end

    it "redirects to the specimen show page on success" do
      post specimens_path, params: valid_params
      expect(response).to redirect_to(specimen_path(Specimen.last))
      expect(flash[:notice]).to be_present
    end

    it "flags works as manual_input when the checkbox is set" do
      post specimens_path, params: valid_params.deep_merge(specimen: { manual_input: "1" })
      expect(Specimen.last.works.pluck(:manual_input).uniq).to eq([ true ])
    end

    it "does not flag works when manual_input is not set" do
      post specimens_path, params: valid_params
      expect(Specimen.last.works.pluck(:manual_input).uniq).to eq([ false ])
    end

    it "renders the form again with errors when no examination is selected" do
      expect {
        post specimens_path, params: valid_params.deep_merge(specimen: { examination_ids: [] })
      }.not_to change(Specimen, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Spesimen Baru")
    end

    it "rejects inactive examination ids" do
      expect {
        post specimens_path, params: valid_params.deep_merge(
          specimen: { examination_ids: [ examination_a.id, inactive_exam.id ] }
        )
      }.not_to change(Specimen, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(flash[:alert]).to include("inactive")
    end

    it "requires patient name, patient id, and birth date" do
      expect {
        post specimens_path, params: valid_params.deep_merge(
          specimen: { patient_name: "", patient_id: "", birth_date: "" }
        )
      }.not_to change(Specimen, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
