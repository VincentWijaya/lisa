module Works
  class CancelService
    def self.call(work:)
      new(work: work).call
    end

    def initialize(work:)
      @work = work
    end

    def call
      return ServiceResult.failure(errors: work.errors.full_messages.presence || ["Work could not be cancelled"]) unless work.update(status: Work.statuses[:cancelled], cancelled_at: Time.current)

      ServiceResult.success(work: work)
    end

    private

    attr_reader :work
  end
end
