require "rails_helper"

RSpec.describe Works::BarcodeGenerator, type: :service do
  describe "#create!" do
    it "creates a barcode using the specimen order number and label sequence" do
      specimen = create(:specimen, order_number: "2605250001")
      examination = create(:examination, code: "CBC__DIFF", specimen_type: "Blood")

      work = described_class.new(specimen: specimen, examination: examination, label_sequence: 1).create!

      expect(work.barcode_id).to eq("2605250001-01")
      expect(work.test_codes_text).to eq("CBC__DIFF;")
      expect(work.specimen_type).to eq("Blood")
    end
  end

  describe Works::WorkCreationService do
    it "groups examinations sharing a label group into a single work" do
      specimen = create(:specimen, order_number: "2605250002")
      glucose = create(:examination, code: "GLU-Slik", label_group: "chem", specimen_type: "Serum")
      urea = create(:examination, code: "UR", label_group: "chem", specimen_type: "Serum")
      creatinine = create(:examination, code: "CRE", specimen_type: "Serum")

      result = described_class.call(specimen: specimen, examinations: [glucose, urea, creatinine])

      expect(result).to be_success
      expect(result.works.size).to eq(2)
      expect(result.works.first.barcode_id).to eq("2605250002-01")
      expect(result.works.first.test_codes_text).to eq("GLU-Slik; UR;")
      expect(result.works.second.barcode_id).to eq("2605250002-02")
      expect(result.works.second.test_codes_text).to eq("CRE;")
    end
  end
end
