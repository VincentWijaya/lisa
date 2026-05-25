require "rails_helper"

RSpec.describe ReferenceRule, type: :model do
  subject(:reference_rule) { build(:reference_rule) }

  describe "associations" do
    it { is_expected.to belong_to(:examination) }
    it { is_expected.to have_many(:examination_results).dependent(:nullify) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:result_type) }
    it { is_expected.to define_enum_for(:result_type).backed_by_column_of_type(:string).with_values(numeric: "numeric", qualitative: "qualitative", text: "text") }
  end

  it "interprets numeric values within range as normal" do
    expect(reference_rule.interpretation_for("5.0")).to eq("normal")
  end

  it "interprets numeric values outside range as abnormal" do
    expect(reference_rule.interpretation_for("7.0")).to eq("abnormal")
  end

  it "returns critical when critical value matches" do
    reference_rule.critical_values = ["PANIC"]
    reference_rule.result_type = "qualitative"

    expect(reference_rule.interpretation_for("PANIC")).to eq("critical")
  end
end
