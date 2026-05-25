require "rails_helper"

RSpec.describe ExaminationResult, type: :model do
  subject(:examination_result) { build(:examination_result) }

  describe "associations" do
    it { is_expected.to belong_to(:work) }
    it { is_expected.to belong_to(:reference_rule).optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:result_value) }
    it { is_expected.to validate_presence_of(:source) }
    it { is_expected.to define_enum_for(:source).backed_by_column_of_type(:string).with_values(manual: "manual", external_api: "external_api", instrument: "instrument") }
  end

  it "rejects result values outside of allowed_values" do
    reference_rule = create(:reference_rule, result_type: "qualitative", allowed_values: ["Negative", "Positive"])
    examination_result.reference_rule = reference_rule
    examination_result.result_value = "Invalid"

    expect(examination_result).not_to be_valid
    expect(examination_result.errors[:result_value]).to include("must be one of: Negative, Positive")
  end

  it "auto-sets interpretation from the reference rule" do
    reference_rule = create(:reference_rule, normal_values: ["Negative"], result_type: "qualitative")
    result = build(:examination_result, reference_rule: reference_rule, result_value: "Negative", interpretation: nil)

    result.save!

    expect(result.interpretation).to eq("normal")
  end
end
