class WorksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_work, only: %i[show update validate_work verify_work verify_all_results cancel_work barcode_label add_result upsert_results scan_validate generate_ai_summary]

  def index
    scope = Work.with_details
                .order(created_at: :desc)
                .search(params[:q])
                .filter_by_status(params[:status])
                .distinct
    @pagy, @works = pagy(:countless, scope, limit: 10)
  end

  def show
    @results = @work.examination_results.includes(:reference_rule).order(created_at: :desc)
    @reference_rules = ReferenceRule.active
                                    .where(examination_id: eligible_examination_ids_for(@work))
                                    .for_specimen_gender(@work.specimen.gender)
                                    .includes(:examination)
                                    .order(:id)
    @results_by_reference_rule = @results.group_by(&:reference_rule_id).transform_values(&:first)
  end

  def update
    if @work.update(work_params)
      redirect_to work_path(@work), notice: t("works.flash.summary_saved")
    else
      redirect_to work_path(@work), alert: @work.errors.full_messages.to_sentence
    end
  end

  def validate_work
    transition_result = Works::ValidateService.call(work: @work)
    redirect_with_transition_result(transition_result, success_notice: t("works.flash.validated"))
  end

  def verify_work
    transition_result = Works::VerifyService.call(work: @work)
    redirect_with_transition_result(transition_result, success_notice: t("works.flash.verified"))
  end

  def verify_all_results
    unverified_results = @work.examination_results.where(verified_at: nil)

    if unverified_results.empty?
      redirect_to work_path(@work), alert: t("works.flash.no_results_to_verify")
      return
    end

    errors = []
    ApplicationRecord.transaction do
      unverified_results.each do |result|
        service_result = ExaminationResults::VerifyService.call(
          examination_result: result,
          verified_by: current_user.id
        )
        errors.concat(service_result.errors) unless service_result.success?
      end
      raise ActiveRecord::Rollback if errors.any?
    end

    if errors.any?
      redirect_to work_path(@work), alert: errors.to_sentence
    else
      redirect_to work_path(@work), notice: t("works.flash.results_verified")
    end
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

  def upsert_results
    result = ExaminationResults::UpsertForWorkService.call(
      work: @work,
      params: upsert_results_params,
      entered_by: current_user.id
    )

    if result.success?
      redirect_to work_path(@work), notice: t("works.flash.results_saved")
    else
      redirect_to work_path(@work), alert: result.errors.to_sentence
    end
  end

  def generate_ai_summary
    result = Works::AiSummaryService.call(@work)

    if result.success?
      redirect_to work_path(@work), notice: t("works.flash.ai_summary_generated")
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

  def upsert_results_params
    params[:examination_results]&.permit(results: {}) || {}
  end

  def work_params
    params.require(:work).permit(:ai_summary)
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
