require "rails_helper"

RSpec.describe Examination, type: :model do
  subject(:examination) { build(:examination) }

  describe "associations" do
    it { is_expected.to have_many(:works).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:reference_rules).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to define_enum_for(:status).backed_by_column_of_type(:string).with_values(active: "active", inactive: "inactive") }

    it "validates default_result_type inclusion" do
      examination.default_result_type = "unsupported"

      expect(examination).not_to be_valid
      expect(examination.errors[:default_result_type]).to be_present
    end
  end
end
