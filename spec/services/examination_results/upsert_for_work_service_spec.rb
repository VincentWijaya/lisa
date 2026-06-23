require "rails_helper"

RSpec.describe ExaminationResults::UpsertForWorkService, type: :service do
  let(:examination) { create(:examination, default_unit: "mg/dL") }
  let(:work) { create(:work, examination: examination, status: "validated", verified_at: Time.current, test_codes_text: "#{examination.code};") }
  let(:rule) { create(:reference_rule, examination: examination, unit: "mg/dL", numeric_low_value: 4.0, numeric_high_value: 6.0) }
  let(:other_rule) { create(:reference_rule, examination: examination, unit: "mmol/L") }

  it "creates results for submitted reference rules and skips blank new rows" do
    result = described_class.call(
      work: work,
      entered_by: 42,
      params: {
        results: {
          rule.id.to_s => { reference_rule_id: rule.id, result_value: "5.2", result_unit: "" },
          other_rule.id.to_s => { reference_rule_id: other_rule.id, result_value: "", result_unit: "mmol/L", source: "instrument" }
        }
      }
    )

    expect(result).to be_success
    expect(work.examination_results.count).to eq(1)
    created = work.examination_results.first
    expect(created.reference_rule).to eq(rule)
    expect(created.result_value).to eq("5.2")
    expect(created.result_unit).to eq("mg/dL")
    expect(created.source).to eq("manual")
    expect(created.entered_by).to eq(42)
    expect(created.interpretation).to eq("normal")
  end

  it "updates an existing result for the same reference rule" do
    existing = create(:examination_result, work: work, reference_rule: rule, result_value: "7.1", result_unit: "mg/dL", source: "manual", interpretation: "abnormal")

    result = described_class.call(
      work: work,
      entered_by: 42,
      params: {
        results: {
          rule.id.to_s => { reference_rule_id: rule.id, result_value: "5.4", result_unit: "mmol/L", source: "instrument" }
        }
      }
    )

    expect(result).to be_success
    expect(work.examination_results.count).to eq(1)
    expect(existing.reload.result_value).to eq("5.4")
    expect(existing.result_unit).to eq("mmol/L")
    expect(existing.source).to eq("instrument")
    expect(existing.interpretation).to eq("normal")
  end

  it "rejects invalid sources" do
    result = described_class.call(
      work: work,
      entered_by: 42,
      params: {
        results: {
          rule.id.to_s => { reference_rule_id: rule.id, result_value: "5.4", result_unit: "mg/dL", source: "unknown" }
        }
      }
    )

    expect(result).to be_failure
    expect(result.errors).to include("Source unknown is not valid")
    expect(work.examination_results.count).to eq(0)
  end

  it "rejects reference rules outside the work examinations" do
    outside_rule = create(:reference_rule)

    result = described_class.call(
      work: work,
      entered_by: 42,
      params: {
        results: {
          outside_rule.id.to_s => { reference_rule_id: outside_rule.id, result_value: "5.4", result_unit: "mg/dL" }
        }
      }
    )

    expect(result).to be_failure
    expect(result.errors).to include("Reference rule #{outside_rule.id} not found for this work")
    expect(work.examination_results.count).to eq(0)
  end

  context "with gender-specific reference rules" do
    let(:male_specimen)   { create(:specimen, gender: "Laki-laki") }
    let(:female_specimen) { create(:specimen, gender: "Perempuan") }
    let(:male_work)   { create(:work, specimen: male_specimen,   examination: examination, status: "validated", verified_at: Time.current, test_codes_text: "#{examination.code};") }
    let(:female_work) { create(:work, specimen: female_specimen, examination: examination, status: "validated", verified_at: Time.current, test_codes_text: "#{examination.code};") }
    let!(:male_rule)   { create(:reference_rule, examination: examination, unit: "mg/dL", name: "Rule (Pria)",   gender: "male",   numeric_low_value: 4.0, numeric_high_value: 6.0) }
    let!(:female_rule) { create(:reference_rule, examination: examination, unit: "mg/dL", name: "Rule (Wanita)", gender: "female", numeric_low_value: 4.0, numeric_high_value: 6.0) }

    it "rejects the female rule when specimen is male" do
      result = described_class.call(
        work: male_work,
        entered_by: 42,
        params: { results: { female_rule.id.to_s => { reference_rule_id: female_rule.id, result_value: "5.0", result_unit: "" } } }
      )

      expect(result).to be_failure
      expect(result.errors).to include("Reference rule #{female_rule.id} not found for this work")
      expect(male_work.examination_results.count).to eq(0)
    end

    it "rejects the male rule when specimen is female" do
      result = described_class.call(
        work: female_work,
        entered_by: 42,
        params: { results: { male_rule.id.to_s => { reference_rule_id: male_rule.id, result_value: "5.0", result_unit: "" } } }
      )

      expect(result).to be_failure
      expect(result.errors).to include("Reference rule #{male_rule.id} not found for this work")
    end

    it "upserts the male rule for a male specimen" do
      result = described_class.call(
        work: male_work,
        entered_by: 42,
        params: { results: { male_rule.id.to_s => { reference_rule_id: male_rule.id, result_value: "5.0", result_unit: "" } } }
      )

      expect(result).to be_success
      expect(male_work.examination_results.first.reference_rule).to eq(male_rule)
    end
  end
end
