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

  describe "gender" do
    let(:exam) { create(:examination) }

    it "is optional and defaults to nil (applies to all)" do
      rule = build(:reference_rule, gender: nil)
      expect(rule).to be_valid
    end

    it "accepts male and female" do
      expect(build(:reference_rule, gender: "male")).to be_valid
      expect(build(:reference_rule, gender: "female")).to be_valid
    end
  end

  describe ".for_specimen_gender" do
    let(:exam) { create(:examination) }
    let!(:unisex)   { create(:reference_rule, examination: exam, name: "Unisex",  gender: nil) }
    let!(:male)     { create(:reference_rule, examination: exam, name: "Male",    gender: "male") }
    let!(:female)   { create(:reference_rule, examination: exam, name: "Female",  gender: "female") }

    it "returns unisex + matching gender for known specimen gender" do
      result = ReferenceRule.for_specimen_gender("Laki-laki").where(examination_id: exam.id)
      expect(result).to contain_exactly(unisex, male)
    end

    it "returns unisex + female for Perempuan" do
      result = ReferenceRule.for_specimen_gender("Perempuan").where(examination_id: exam.id)
      expect(result).to contain_exactly(unisex, female)
    end

    it "returns unisex only when specimen gender is unknown" do
      result = ReferenceRule.for_specimen_gender(nil).where(examination_id: exam.id)
      expect(result).to contain_exactly(unisex)
    end
  end

  describe ".best_for_specimen" do
    let(:exam) { create(:examination) }
    let!(:unisex) { create(:reference_rule, examination: exam, name: "Unisex",  gender: nil) }
    let!(:male)   { create(:reference_rule, examination: exam, name: "Male",    gender: "male") }
    let!(:female) { create(:reference_rule, examination: exam, name: "Female",  gender: "female") }

    it "prefers the rule whose gender matches the specimen" do
      expect(ReferenceRule.best_for_specimen([ unisex, male, female ], "Laki-laki")).to eq(male)
      expect(ReferenceRule.best_for_specimen([ unisex, male, female ], "Perempuan")).to eq(female)
    end

    it "falls back to unisex when no gender match" do
      expect(ReferenceRule.best_for_specimen([ unisex, male ], "Perempuan")).to eq(unisex)
    end

    it "falls back to first by id when specimen gender is unknown" do
      expect(ReferenceRule.best_for_specimen([ male, female ], nil)).to eq(male)
    end

    it "returns nil for an empty collection" do
      expect(ReferenceRule.best_for_specimen([], "Laki-laki")).to be_nil
    end
  end
end
