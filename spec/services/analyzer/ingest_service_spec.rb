require "rails_helper"

RSpec.describe Analyzer::IngestService do
  subject(:result) { described_class.call(params) }

  let(:specimen) { create(:specimen, patient_id: "1234", status: "pending") }
  let(:examination) { create(:examination, code: "WBC-PANEL") }
  let!(:work) { create(:work, specimen: specimen, examination: examination, status: "pending") }
  let!(:reference_rule) do
    create(:reference_rule, examination: examination, loinc_code: "6690-2", name: "WBC",
           result_type: "numeric", numeric_low_value: 4.0, numeric_high_value: 10.0)
  end

  let(:params) do
    {
      patient_id: "1234",
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
    it "returns success" do
      expect(result).to be_success
    end

    it "creates an ExaminationResult" do
      expect { result }.to change(ExaminationResult, :count).by(1)
    end

    it "sets result_value as string" do
      result
      expect(ExaminationResult.last.result_value).to eq("7.59")
    end

    it "sets source to instrument" do
      result
      expect(ExaminationResult.last.source).to eq("instrument")
    end

    it "links to the correct reference rule" do
      result
      expect(ExaminationResult.last.reference_rule).to eq(reference_rule)
    end

    it "exposes processed, created, skipped counts" do
      expect(result.processed).to eq(1)
      expect(result.created.length).to eq(1)
      expect(result.skipped_count).to eq(0)
    end
  end

  describe "skipping unmatched results" do
    let(:params) do
      super().merge(results: [
        { loinc: nil, local_code: "08001", test_name: "Take Mode", value: "O", unit: "", reference_range: "", flag: "" }
      ])
    end

    it "does not create any results" do
      expect { result }.not_to change(ExaminationResult, :count)
    end

    it "counts the skip" do
      expect(result.skipped_count).to eq(1)
    end
  end

  describe "matching by local_code" do
    let!(:local_rule) do
      create(:reference_rule, examination: examination, local_code: "08001", loinc_code: nil,
             name: "Take Mode", result_type: "text", allowed_values: [], active: true)
    end
    let(:params) do
      super().merge(results: [
        { loinc: nil, local_code: "08001", test_name: "Take Mode", value: "O", unit: "", reference_range: "", flag: "" }
      ])
    end

    it "creates a result via local_code" do
      expect { result }.to change(ExaminationResult, :count).by(1)
    end
  end

  describe "error cases" do
    context "when specimen is not found" do
      let(:params) { super().merge(patient_id: "UNKNOWN") }

      it { is_expected.to be_failure }

      it "returns a descriptive error" do
        expect(result.errors.first).to match(/No active specimen found/)
      end
    end

    context "when multiple active specimens exist for patient_id" do
      before { create(:specimen, patient_id: "1234", status: "pending") }

      it { is_expected.to be_failure }

      it "returns a descriptive error" do
        expect(result.errors.first).to match(/Multiple active specimens found/)
      end
    end

    context "when patient_id is blank" do
      let(:params) { super().merge(patient_id: "") }

      it { is_expected.to be_failure }
    end

    context "when results is not an array" do
      let(:params) { super().merge(results: "bad") }

      it { is_expected.to be_failure }
    end

    context "when the matching work is cancelled" do
      before { work.update!(status: "cancelled") }

      it "skips the result" do
        expect { result }.not_to change(ExaminationResult, :count)
        expect(result.skipped_count).to eq(1)
      end
    end
  end
end
