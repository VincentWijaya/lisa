module Works
  class ValidateService
    def self.call(work:)
      new(work: work).call
    end

    def initialize(work:)
      @work = work
    end

    def call
      return ServiceResult.failure(errors: work.errors.full_messages.presence || ["Work could not be verified"]) unless work.update(status: Work.statuses[:validated], verified_at: Time.current)

      ServiceResult.success(work: work)
    end

    private

    attr_reader :work
  end
end
