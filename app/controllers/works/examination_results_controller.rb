class Works::ExaminationResultsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_work
  before_action :set_result

  def update
    service_result = ExaminationResults::UpdateService.call(
      examination_result: @result,
      params: result_params
    )
    if service_result.success?
      redirect_to work_path(@work), notice: t("works.flash.result_updated")
    else
      redirect_to work_path(@work), alert: service_result.errors.to_sentence
    end
  end

  def destroy
    @result.destroy!
    redirect_to work_path(@work), notice: t("works.flash.result_deleted")
  end

  def verify
    service_result = ExaminationResults::VerifyService.call(
      examination_result: @result,
      verified_by: current_user.id
    )
    if service_result.success?
      redirect_to work_path(@work), notice: t("works.flash.result_verified")
    else
      redirect_to work_path(@work), alert: service_result.errors.to_sentence
    end
  end

  private

  def set_work
    @work = Work.find(params[:work_id])
  end

  def set_result
    @result = @work.examination_results.find(params[:id])
  end

  def result_params
    params.require(:examination_result).permit(:result_value, :result_unit, :reference_rule_id)
  end
end
