class WorksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_work, only: %i[show validate_work verify_work cancel_work barcode_label add_result scan_validate]

  def index
    scope = Work.with_details
                .order(created_at: :desc)
                .filter_by_status(params[:status])
                .filter_by_lab_id(params[:lab_id])
                .search_term(params[:query])
                .distinct
    @pagy, @works = pagy(:countless, scope, limit: 10)
  end

  def show
    @results = @work.examination_results.includes(:reference_rule).order(created_at: :desc)
    @reference_rules = ReferenceRule.active.where(examination_id: eligible_examination_ids_for(@work))
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

  def scan_validate
    scanned_id = params[:barcode_id].to_s.strip

    if scanned_id != @work.barcode_id
      redirect_to work_path(@work), alert: t("works.flash.barcode_mismatch", scanned: scanned_id, expected: @work.barcode_id)
      return
    end

    unless @work.pending?
      redirect_to work_path(@work), alert: t("works.flash.work_not_pending", status: t("works.status.#{@work.status}"))
      return
    end

    transition_result = Works::ValidateService.call(work: @work)
    redirect_with_transition_result(transition_result, success_notice: t("works.flash.validated"))
  end

  def barcode_label
    @label_data = Works::LabelDataService.call(@work)
    render layout: "print"
  end

  def add_result
    result = ExaminationResults::CreateService.call(
      work: @work,
      params: result_params.merge(entered_by: current_user.id)
    )
    if result.success?
      redirect_to work_path(@work), notice: t("works.flash.result_added")
    else
      redirect_to work_path(@work), alert: result.errors.to_sentence
    end
  end

  private

  def set_work
    @work = Work.includes(:specimen, :examination, :examination_results).find(params[:id])
  end

  def result_params
    params.require(:examination_result).permit(:result_value, :result_unit, :reference_rule_id)
  end

  def eligible_examination_ids_for(work)
    codes = work.test_codes_text.to_s.split(";").map(&:strip).reject(&:blank?)
    ids = Examination.where(code: codes).pluck(:id)
    ids.presence || [work.examination_id]
  end

  def redirect_with_transition_result(result, success_notice:)
    if result.success?
      redirect_back fallback_location: work_path(@work), notice: success_notice
    else
      redirect_back fallback_location: work_path(@work), alert: result.errors.to_sentence
    end
  end
end
