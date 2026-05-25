require "rails_helper"

RSpec.describe Specimens::CreateService, type: :service do
  describe ".call" do
    let!(:examination) { create(:examination, code: "CBC") }

    it "creates a specimen and related works" do
      result = described_class.call(
        patient_id: "12345",
        patient_name: "Jane Doe",
        birth_date: Date.new(1990, 5, 15),
        gender: "Female",
        medical_record_id: "MR-2026-0001",
        lab_id: "LAB123",
        department: "ER",
        collection_datetime: Time.zone.parse("2026-05-25 10:30:00"),
        examination_ids: [examination.id]
      )

      expect(result).to be_success
      expect(result.specimen.order_number).to match(/\A\d{10}\z/)
      expect(result.specimen.works.count).to eq(1)
      expect(result.specimen.works.first.barcode_id).to end_with("-01")
    end

    it "returns validation errors for inactive or missing examinations" do
      result = described_class.call(
        patient_id: "12345",
        patient_name: "Jane Doe",
        birth_date: Date.new(1990, 5, 15),
        gender: "Female",
        lab_id: "LAB123",
        examination_ids: [999_999]
      )

      expect(result).not_to be_success
      expect(result.errors).to include("Examination 999999 not found or inactive")
    end

    it "rolls back the specimen when grouped examinations are incompatible" do
      before_count = Specimen.count
      grouped_a = create(:examination, code: "GLU", label_group: "chem", specimen_type: "Serum")
      grouped_b = create(:examination, code: "UR", label_group: "chem", specimen_type: "Urine")

      result = described_class.call(
        patient_id: "12345",
        patient_name: "Jane Doe",
        birth_date: Date.new(1990, 5, 15),
        gender: "Female",
        lab_id: "LAB123",
        examination_ids: [grouped_a.id, grouped_b.id]
      )

      expect(result).not_to be_success
      expect(result.errors).to include("Grouped examinations must share the same specimen type for label group chem")
      expect(Specimen.count).to eq(before_count)
    end
  end
end
