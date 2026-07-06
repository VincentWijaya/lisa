module ExaminationResults
  class ComputedResultCalculator
    class FormulaError < StandardError; end

    def self.call(expression:, inputs:)
      new(expression: expression, inputs: inputs).call
    end

    def initialize(expression:, inputs:)
      @expression = expression.to_s
      @inputs = Array(inputs)
    end

    def call
      return nil if @expression.blank? || @inputs.empty?

      values = resolve_values
      return nil if values.nil?

      result = eval(expression_with_codes_replaced(values))
      result.finite? ? result : nil
    rescue FormulaError, ArgumentError, TypeError, SyntaxError
      nil
    end

    private

    def resolve_values
      @inputs.each_with_object({}) do |input, hash|
        code = input["code"] || input[:code]
        value = input["value"] || input[:value]
        return nil if code.blank? || value.nil?

        numeric = Float(value.to_s)
        hash[code.to_s] = numeric
      end
    rescue ArgumentError, TypeError
      nil
    end

    def expression_with_codes_replaced(values)
      @expression.gsub(/[A-Za-z_][A-Za-z0-9_#]*/) do |token|
        next token if RESERVED.include?(token.downcase)

        values.fetch(token) { raise FormulaError, "Unknown input: #{token}" }
      end
    end

    RESERVED = %w[true false nil].freeze
  end
end
