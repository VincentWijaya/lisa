require "rails_helper"

RSpec.describe Analyzer::IngestService do
  # Declare an explicit execution command helper to prevent mutating states unexpectedly
  def trigger_service
    described_class.call(params)
  end

  let(:specimen) { create(:specimen, patient_id: "1234", status: "pending") }
  let(:examination) { create(:examination, code: "WBC") }

  let!(:work) do
    create(:work,
           specimen: specimen,
           examination: examination,
           status: "pending",
           barcode_id: "2605250054-01",
           label_sequence: 1,
           test_codes_text: "WBC;")
  end

  let!(:reference_rule) do
    create(:reference_rule,
           examination: examination,
           loinc_code: "6690-2",
           name: "WBC",
           result_type: "numeric",
           numeric_low_value: 4.0,
           numeric_high_value: 10.0,
           active: true)
  end

  let(:params) do
    {
      barcode_id: "2605250054-01",
      gender: "Female",
      message_datetime: "20260316150051",
      message_control_id: "3",
      results: [
        { loinc: "6690-2", local_code: nil, test_name: "WBC", value: 7.59, unit: "10*3/uL",
          reference_range: "4.00-10.00", flag: "N" }
      ]
    }
  end

  describe "happy path" do
    it "returns success and creates an ExaminationResult correctly" do
      # Run exactly once inside this block to prevent shared mutation state side-effects
      service_result = nil
      expect { service_result = trigger_service }.to change(ExaminationResult, :count).by(1)

      expect(service_result).to be_success
      expect(service_result.processed).to eq(1)
      expect(service_result.created).to eq(1)
      expect(service_result.skipped_count).to eq(0)

      created_record = ExaminationResult.last
      expect(created_record.result_value).to eq("7.59")
      expect(created_record.source).to eq("instrument")
      expect(created_record.reference_rule).to eq(reference_rule)
    end
  end

  describe "skipping unmatched results" do
    let(:params) do
      {
        barcode_id: "2605250054-01",
        gender: "Female",
        message_datetime: "20260316150051",
        message_control_id: "3",
        results: [
          { loinc: nil, local_code: "08001", test_name: "Take Mode", value: "O", unit: "", reference_range: "", flag: "" }
        ]
      }
    end

    it "does not create any results and counts the skip" do
      service_result = nil
      expect { service_result = trigger_service }.not_to change(ExaminationResult, :count)
      expect(service_result.skipped_count).to eq(1)
    end
  end

  describe "matching by local_code" do
    let(:local_examination) { create(:examination, code: "TAKEMODE") }

    let!(:local_work) do
      create(:work,
             specimen: specimen,
             examination: local_examination,
             status: "pending",
             barcode_id: "2605250054-02",
             label_sequence: 2,
             test_codes_text: "TAKEMODE;")
    end

    let!(:local_rule) do
      create(:reference_rule,
             examination: local_examination,
             local_code: "08001",
             loinc_code: nil,
             name: "Take Mode",
             result_type: "text",
             allowed_values: [],
             active: true)
    end

    let(:params) do
      {
        barcode_id: "2605250054-02",
        gender: "Female",
        message_datetime: "20260316150051",
        message_control_id: "3",
        results: [
          { loinc: nil, local_code: "08001", test_name: "Take Mode", value: "O", unit: "", reference_range: "", flag: "" }
        ]
      }
    end

    it "creates a result via local_code" do
      expect { trigger_service }.to change(ExaminationResult, :count).by(1)
    end
  end

  describe "error cases" do
    context "when work is not found" do
      let(:params) { super().merge(barcode_id: "UNKNOWN") }

      it "returns a failure and a descriptive error" do
        res = trigger_service
        expect(res).to be_failure
        expect(res.errors.first).to match(/No active work found/)
      end
    end

    context "when barcode_id is blank" do
      let(:params) { super().merge(barcode_id: "") }

      it "returns failure status" do
        expect(trigger_service).to be_failure
      end
    end

    context "when results is not an array" do
      let(:params) { super().merge(results: "bad") }

      it "returns failure status" do
        expect(trigger_service).to be_failure
      end
    end

    context "when the matching work is cancelled" do
      before do
        work.update!(status: "cancelled")
        create(:work,
               specimen: specimen,
               examination: examination,
               status: "pending",
               barcode_id: "2605250054-99",
               label_sequence: 99,
               test_codes_text: "OTHER;")
      end
      let(:params) { super().merge(barcode_id: "2605250054-99") }

      it "skips the result because the matched work is not in the result's test code map" do
        res = nil
        expect { res = trigger_service }.not_to change(ExaminationResult, :count)
        expect(res.skipped_count).to eq(1)
      end
    end
  end

  describe "gender-specific reference rules" do
    let!(:male_rule) do
      create(:reference_rule,
             examination: examination,
             loinc_code: "6690-2",
             name: "WBC (Pria)",
             result_type: "numeric",
             numeric_low_value: 4.0,
             numeric_high_value: 10.0,
             gender: "male",
             active: true)
    end
    let!(:female_rule) do
      create(:reference_rule,
             examination: examination,
             loinc_code: "6690-2",
             name: "WBC (Wanita)",
             result_type: "numeric",
             numeric_low_value: 4.0,
             numeric_high_value: 10.0,
             gender: "female",
             active: true)
    end

    context "when specimen is male" do
      let(:specimen) { create(:specimen, patient_id: "1234", gender: "Laki-laki", status: "pending") }

      it "writes the result to the male rule" do
        trigger_service
        result = work.examination_results.find_by(reference_rule: male_rule)
        expect(result).to be_present
        expect(result.result_value).to eq("7.59")
        expect(work.examination_results.find_by(reference_rule: female_rule)).to be_nil
      end
    end

    context "when specimen is female" do
      let(:specimen) { create(:specimen, patient_id: "1234", gender: "Perempuan", status: "pending") }

      it "writes the result to the female rule" do
        trigger_service
        result = work.examination_results.find_by(reference_rule: female_rule)
        expect(result).to be_present
        expect(result.result_value).to eq("7.59")
        expect(work.examination_results.find_by(reference_rule: male_rule)).to be_nil
      end
    end
  end
end
