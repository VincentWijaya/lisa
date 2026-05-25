class WorksController < ApplicationController
  before_action :set_work, only: %i[show validate_work verify_work cancel_work barcode_label]

  def index
    @works = Work.with_details
                 .order(created_at: :desc)
                 .filter_by_status(params[:status])
                 .filter_by_lab_id(params[:lab_id])
                 .search_term(params[:query])
                 .distinct
  end

  def show
    @results = @work.examination_results.order(created_at: :desc)
  end

  def validate_work
    transition_work(status: Work.statuses[:validated], timestamp: { validated_at: Time.current }, notice: "Work validated successfully.")
  end

  def verify_work
    ActiveRecord::Base.transaction do
      @work.update!(status: Work.statuses[:verified], verified_at: Time.current)
      complete_specimen_if_done!(@work.specimen)
    end

    redirect_back fallback_location: work_path(@work), notice: "Work verified successfully."
  rescue ActiveRecord::RecordInvalid => e
    redirect_back fallback_location: work_path(@work), alert: e.record.errors.full_messages.to_sentence
  end

  def cancel_work
    transition_work(status: Work.statuses[:cancelled], timestamp: { cancelled_at: Time.current }, notice: "Work cancelled successfully.")
  end

  def barcode_label
    @label_data = Works::LabelDataService.call(@work)
    render layout: "print"
  end

  private

  def set_work
    @work = Work.includes(:specimen, :examination, :examination_results).find(params[:id])
  end

  def transition_work(status:, timestamp:, notice:)
    if @work.update({ status: status }.merge(timestamp))
      redirect_back fallback_location: work_path(@work), notice: notice
    else
      redirect_back fallback_location: work_path(@work), alert: @work.errors.full_messages.to_sentence
    end
  end

  def complete_specimen_if_done!(specimen)
    return unless specimen.works.where.not(status: %w[verified cancelled]).none?

    specimen.update!(status: Specimen.statuses[:complete], completion_datetime: Time.current)
  end
end
