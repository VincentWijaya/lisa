require "rails_helper"

RSpec.describe ExaminationResults::ComputedResultCalculator do
  describe ".call" do
    it "evaluates a simple subtraction" do
      result = described_class.call(
        expression: "TP - ALB",
        inputs: [{ "code" => "TP", "value" => "7.5" }, { "code" => "ALB", "value" => "4.2" }]
      )
      expect(result).to eq(3.3)
    end

    it "evaluates a Friedewald-style LDL formula" do
      result = described_class.call(
        expression: "CHOL - (TG / 5) - HDL",
        inputs: [
          { "code" => "CHOL", "value" => "200" },
          { "code" => "TG",   "value" => "150" },
          { "code" => "HDL",  "value" => "50"  }
        ]
      )
      expect(result).to eq(120.0)
    end

    it "evaluates an NLR ratio with hash-rock input code" do
      result = described_class.call(
        expression: "NEU# / LYM#",
        inputs: [{ "code" => "NEU#", "value" => "5.0" }, { "code" => "LYM#", "value" => "2.0" }]
      )
      expect(result).to eq(2.5)
    end

    it "returns nil when an input is missing" do
      result = described_class.call(
        expression: "A + B",
        inputs: [{ "code" => "A", "value" => "1" }]
      )
      expect(result).to be_nil
    end

    it "returns nil when expression is blank" do
      result = described_class.call(expression: "", inputs: [{ "code" => "A", "value" => "1" }])
      expect(result).to be_nil
    end

    it "returns nil when input value is not numeric" do
      result = described_class.call(
        expression: "A + B",
        inputs: [{ "code" => "A", "value" => "abc" }, { "code" => "B", "value" => "1" }]
      )
      expect(result).to be_nil
    end

    it "returns nil on division by zero" do
      result = described_class.call(
        expression: "A / B",
        inputs: [{ "code" => "A", "value" => "5" }, { "code" => "B", "value" => "0" }]
      )
      expect(result).to be_nil
    end

    it "returns nil when an unknown code is referenced" do
      result = described_class.call(
        expression: "FOO + MISSING",
        inputs: [{ "code" => "FOO", "value" => "1" }]
      )
      expect(result).to be_nil
    end
  end
end
