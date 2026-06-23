module ExaminationResults
  class UpdateService
    def self.call(examination_result:, params:)
      new(examination_result: examination_result, params: params).call
    end

    def initialize(examination_result:, params:)
      @examination_result = examination_result
      @work               = examination_result.work
      @params             = params.to_h.deep_symbolize_keys
      @errors             = []
    end

    def call
      return ServiceResult.failure(errors: ["Results can only be edited for pending or validated works"]) unless work.pending? || work.validated?
      return ServiceResult.failure(errors: ["Reference rule is required"]) if params[:reference_rule_id].blank?

      reference_rule = find_reference_rule
      return ServiceResult.failure(errors: @errors) if @errors.any?

      examination_result.update!(
        result_value:   params[:result_value],
        result_unit:    params[:result_unit].presence || reference_rule&.unit || work.examination.default_unit,
        reference_rule: reference_rule,
        interpretation: nil
      )

      ServiceResult.success(examination_result: examination_result)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure(errors: e.record.errors.full_messages)
    end

    private

    attr_reader :examination_result, :work, :params

    def find_reference_rule
      scope = ReferenceRule.active
                           .for_specimen_gender(work.specimen.gender)
      scope.find_by(id: params[:reference_rule_id]).tap do |rule|
        @errors << "Reference rule not found" if rule.nil?
      end
    end
  end
end
