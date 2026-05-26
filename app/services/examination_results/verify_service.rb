module ExaminationResults
  class VerifyService
    def self.call(examination_result:, verified_by:)
      new(examination_result: examination_result, verified_by: verified_by).call
    end

    def initialize(examination_result:, verified_by:)
      @examination_result = examination_result
      @verified_by        = verified_by
    end

    def call
      examination_result.update!(
        verified_at: Time.current,
        verified_by: @verified_by
      )
      ServiceResult.success(examination_result: examination_result)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure(errors: e.record.errors.full_messages)
    end

    private

    attr_reader :examination_result
  end
end
