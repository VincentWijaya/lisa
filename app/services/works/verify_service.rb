module Works
  class VerifyService
    def self.call(work:)
      new(work: work).call
    end

    def initialize(work:)
      @work = work
    end

    def call
      ActiveRecord::Base.transaction do
        work.update!(status: Work.statuses[:verified], verified_at: Time.current)
        complete_specimen_if_needed!
      end

      ServiceResult.success(work: work)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure(errors: e.record.errors.full_messages.presence || ["Work could not be verified"])
    end

    private

    attr_reader :work

    def complete_specimen_if_needed!
      specimen = work.specimen
      return unless specimen.works.where.not(status: [Work.statuses[:verified], Work.statuses[:cancelled]]).none?

      specimen.update!(status: Specimen.statuses[:complete], completion_datetime: Time.current)
    end
  end
end
