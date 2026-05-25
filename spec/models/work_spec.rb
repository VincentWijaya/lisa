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

      expect(persisted_work.update(status: "validated", validated_at: Time.current)).to be(true)
    end

    it "prevents pending to verified" do
      persisted_work = create(:work, status: "pending")

      expect(persisted_work.update(status: "verified", verified_at: Time.current)).to be(false)
      expect(persisted_work.errors[:status]).to include("cannot transition from 'pending' to 'verified'")
    end
  end
end
