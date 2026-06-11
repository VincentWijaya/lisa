module ExaminationResults
  class UpsertForWorkService
    def self.call(work:, params:, entered_by:)
      new(work: work, params: params, entered_by: entered_by).call
    end

    def initialize(work:, params:, entered_by:)
      @work = work
      @params = params.to_h.deep_symbolize_keys
      @entered_by = entered_by
      @errors = []
      @upserted_results = []
    end

    def call
      return ServiceResult.failure(errors: ["Results can only be saved for pending or validated works"]) unless work.pending? || work.validated?

      ExaminationResult.transaction do
        result_rows.each do |row|
          reference_rule = find_reference_rule(row[:reference_rule_id])
          next unless reference_rule
          next if row[:result_value].blank? && existing_result_for(reference_rule).blank?

          upsert_result(reference_rule, row)
        end

        raise ActiveRecord::Rollback if errors.any?
      end

      return ServiceResult.failure(errors: errors) if errors.any?

      ServiceResult.success(examination_results: upserted_results)
    end

    private

    attr_reader :work, :params, :entered_by, :errors, :upserted_results

    def result_rows
      Array(params.fetch(:results, {}).values).map { |row| row.to_h.deep_symbolize_keys }
    end

    def find_reference_rule(id)
      reference_rules_by_id[id.to_i].tap do |reference_rule|
        errors << "Reference rule #{id} not found for this work" if reference_rule.nil?
      end
    end

    def upsert_result(reference_rule, row)
      result = existing_result_for(reference_rule) || work.examination_results.build(reference_rule: reference_rule)
      result.assign_attributes(
        result_value: row[:result_value],
        result_unit: row[:result_unit].presence || reference_rule.unit.presence || work.examination.default_unit,
        interpretation: nil
      )

      if result.new_record?
        result.source = ExaminationResult.sources[:manual]
        result.entered_by = entered_by
      end

      result.save!
      upserted_results << result
    rescue ActiveRecord::RecordInvalid => e
      errors.concat(e.record.errors.full_messages)
    end

    def existing_result_for(reference_rule)
      existing_results_by_reference_rule[reference_rule.id]
    end

    def existing_results_by_reference_rule
      @existing_results_by_reference_rule ||= work.examination_results
                                                .where(reference_rule_id: reference_rules_by_id.keys)
                                                .order(created_at: :desc)
                                                .group_by(&:reference_rule_id)
                                                .transform_values(&:first)
    end

    def reference_rules_by_id
      @reference_rules_by_id ||= ReferenceRule.active
                                             .where(examination_id: eligible_examination_ids)
                                             .index_by(&:id)
    end

    def eligible_examination_ids
      @eligible_examination_ids ||= begin
        codes = work.test_codes_text.to_s.split(";").map(&:strip).reject(&:blank?)
        ids = Examination.where(code: codes).pluck(:id)
        ids.presence || [work.examination_id]
      end
    end
  end
end
