module ExaminationResults
  class CreateService
    def self.call(work:, params:)
      new(work: work, params: params).call
    end

    def initialize(work:, params:)
      @work = work
      @params = params.to_h.deep_symbolize_keys
    end

    def call
      return ServiceResult.failure(errors: ["Results can only be entered for pending or validated works"]) unless work.pending? || work.validated?

      reference_rule = selected_reference_rule
      return ServiceResult.failure(errors: errors) if errors.any?

      examination_result = work.examination_results.create!(
        result_value: params[:result_value],
        result_unit: params[:result_unit].presence || reference_rule&.unit || work.examination.default_unit,
        reference_rule: reference_rule,
        source: params[:source].presence || ExaminationResult.sources[:manual],
        entered_by: params[:entered_by],
        verified_by: params[:verified_by],
        verified_at: params[:verified_at]
      )

      ServiceResult.success(examination_result: examination_result)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure(errors: e.record.errors.full_messages)
    end

    private

    attr_reader :work, :params

    def errors
      @errors ||= []
    end

    def selected_reference_rule
      return default_reference_rule unless params[:reference_rule_id].present?

      reference_rule_scope.find_by(id: params[:reference_rule_id]).tap do |reference_rule|
        errors << "Reference rule #{params[:reference_rule_id]} not found for this work" if reference_rule.nil?
      end
    end

    def default_reference_rule
      reference_rule_scope.order(:id).first
    end

    def reference_rule_scope
      ReferenceRule.active.where(examination_id: eligible_examination_ids)
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
