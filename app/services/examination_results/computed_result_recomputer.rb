module ExaminationResults
  class ComputedResultRecomputer
    def self.call(specimen:, entered_by: nil)
      new(specimen: specimen, entered_by: entered_by).call
    end

    def initialize(specimen:, entered_by:)
      @specimen = specimen
      @entered_by = entered_by
    end

    def call
      rules = formula_rules
      return ServiceResult.success(updated: 0) if rules.empty?

      source_values = collect_source_values
      updated = 0

      ActiveRecord::Base.transaction do
        rules.each do |rule|
          inputs = rule.formula_inputs.map { |i| i["code"] || i[:code] }
          next if inputs.any? { |code| source_values[code].nil? }

          value = ComputedResultCalculator.call(
            expression: rule.formula_expression,
            inputs: inputs.map { |c| { "code" => c, "value" => source_values[c] } }
          )
          next if value.nil?

          persist(rule: rule, value: value)
          updated += 1
        end
      end

      ServiceResult.success(updated: updated)
    end

    private

    attr_reader :specimen, :entered_by

    def formula_rules
      ReferenceRule.active
                   .where.not(formula_expression: [nil, ""])
                   .where.not(formula_inputs: [nil, "[]", "{}"])
                   .distinct
    end

    def collect_source_values
      codes = formula_rules.flat_map { |r| r.formula_inputs.map { |i| i["code"] || i[:code] } }.uniq
      return {} if codes.empty?

      latest = ExaminationResult.joins(work: :specimen, reference_rule: :examination)
                                .where(specimens: { id: specimen.id })
                                .where.not(works: { status: "cancelled" })
                                .where(examinations: { code: codes })
                                .where.not(result_value: [nil, ""])
                                .order("examination_results.created_at DESC")
                                .select("examination_results.result_value, examinations.code")
                                .to_a

      latest.each_with_object({}) do |row, hash|
        hash[row.code] ||= row.result_value
      end
    end

    def persist(rule:, value:)
      formatted = format_value(value)
      target_work = ensure_work_for(rule.examination)
      return if target_work.nil?

      existing = ExaminationResult.where(work_id: target_work.id, reference_rule_id: rule.id)
                                  .order(created_at: :desc)
                                  .first

      attrs = {
        result_value: formatted,
        result_unit: rule.unit.presence || rule.examination.default_unit,
        source: "instrument",
        interpretation: rule.interpretation_for(formatted)
      }

      if existing
        existing.update!(attrs)
      else
        ExaminationResult.create!(
          attrs.merge(
            work_id: target_work.id,
            reference_rule_id: rule.id,
            entered_by: entered_by
          )
        )
      end
    end

    def ensure_work_for(examination)
      existing = specimen.works.where(examination_id: examination.id, status: %w[pending validated verified]).first
      return existing if existing

      next_sequence = (specimen.works.maximum(:label_sequence) || 0) + 1
      generator = Works::BarcodeGenerator.new(
        specimen: specimen,
        examination: examination,
        label_sequence: next_sequence
      )
      generator.create!
    rescue ActiveRecord::RecordInvalid
      nil
    end

    def format_value(value)
      numeric = value.to_f
      return numeric.to_i.to_s if numeric == numeric.to_i

      format("%.4f", numeric).sub(/\.?0+$/, "")
    end
  end
end
