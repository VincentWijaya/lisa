require "rails_helper"

RSpec.describe Work, type: :model do
  subject(:work) { build(:work) }

  describe "associations" do
    it { is_expected.to belong_to(:specimen) }
    it { is_expected.to belong_to(:examination) }
    it { is_expected.to have_many(:examination_results).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:barcode_id) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_numericality_of(:label_sequence).is_greater_than(0).only_integer }
    it { is_expected.to define_enum_for(:status).backed_by_column_of_type(:string).with_values(pending: "pending", validated: "validated", verified: "verified", cancelled: "cancelled") }
  end

  describe "status transitions" do
    it "allows pending to validated" do
      persisted_work = create(:work, status: "pending")

      expect(persisted_work.update(status: "validated", verified_at: Time.current)).to be(true)
    end

    it "prevents pending to verified" do
      persisted_work = create(:work, status: "pending")

      expect(persisted_work.update(status: "verified", validated_at: Time.current)).to be(false)
      expect(persisted_work.errors[:status]).to include("cannot transition from 'pending' to 'verified'")
    end
  end

  describe ".search" do
    let!(:specimen_a) { create(:specimen, patient_name: "Marjolaine Landing", patient_id: "P-10005", medical_record_id: "RM-2004-005", order_number: "2606090095") }
    let!(:specimen_b) { create(:specimen, patient_name: "Budi Santoso",       patient_id: "P-20007", medical_record_id: "RM-2004-099", order_number: "2606090099") }
    let!(:work_a)     { create(:work, specimen: specimen_a, barcode_id: "2606090095-01") }
    let!(:work_b)     { create(:work, specimen: specimen_b, barcode_id: "2606090099-01") }

    it "returns all works when query is blank" do
      expect(Work.search(nil)).to include(work_a, work_b)
      expect(Work.search("")).to include(work_a, work_b)
    end

    it "matches by exact barcode_id" do
      expect(Work.search("2606090095-01")).to include(work_a)
      expect(Work.search("2606090095-01")).not_to include(work_b)
    end

    it "matches by exact patient name" do
      expect(Work.search("Marjolaine Landing")).to include(work_a)
      expect(Work.search("Marjolaine Landing")).not_to include(work_b)
    end

    it "matches by exact medical record id" do
      expect(Work.search("RM-2004-005")).to include(work_a)
      expect(Work.search("RM-2004-005")).not_to include(work_b)
    end

    it "matches by exact order number" do
      expect(Work.search("2606090095")).to include(work_a)
      expect(Work.search("2606090095")).not_to include(work_b)
    end

    it "uses exact equality, never LIKE" do
      sql = Work.search("2606%").to_sql
      expect(sql).not_to include("LIKE")
      expect(sql).not_to include("like")
      expect(Work.search("2606%")).to be_empty
    end
  end
end
