class WorksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_work, only: %i[show validate_work verify_work cancel_work barcode_label]

  def index
    scope = Work.with_details
                .order(created_at: :desc)
                .filter_by_status(params[:status])
                .filter_by_lab_id(params[:lab_id])
                .search_term(params[:query])
                .distinct
    @pagy, @works = pagy(scope, limit: 25)
  end

  def show
    @results = @work.examination_results.order(created_at: :desc)
  end

  def validate_work
    transition_result = Works::ValidateService.call(work: @work)
    redirect_with_transition_result(transition_result, success_notice: t("works.flash.validated"))
  end

  def verify_work
    transition_result = Works::VerifyService.call(work: @work)
    redirect_with_transition_result(transition_result, success_notice: t("works.flash.verified"))
  end

  def cancel_work
    transition_result = Works::CancelService.call(work: @work)
    redirect_with_transition_result(transition_result, success_notice: t("works.flash.cancelled"))
  end

  def barcode_label
    @label_data = Works::LabelDataService.call(@work)
    render layout: "print"
  end

  private

  def set_work
    @work = Work.includes(:specimen, :examination, :examination_results).find(params[:id])
  end

  def redirect_with_transition_result(result, success_notice:)
    if result.success?
      redirect_back fallback_location: work_path(@work), notice: success_notice
    else
      redirect_back fallback_location: work_path(@work), alert: result.errors.to_sentence
    end
  end
end
