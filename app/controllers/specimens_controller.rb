class SpecimensController < ApplicationController
  before_action :authenticate_user!
  before_action :set_specimen, only: %i[show update barcode_labels print_report send_report send_report_form send_whatsapp generate_ai_summary]

  def index
    scope = Specimen.with_works
                    .search(params[:q])
                    .filter_by_status(params[:status])
                    .filter_by_patient_name(params[:patient_name])
                    .filter_by_medical_record_id(params[:medical_record_id])
                    .filter_by_order_number(params[:order_number])
                    .order(created_at: :desc)
    @pagy, @specimens = pagy(scope, limit: 10)
  end

  def new
    @examination_groups = Examination.active
                                      .order(:category, :name)
                                      .group_by(&:category)
    @specimen = Specimen.new(
      gender: "Laki-laki"
    )
  end

  def create
    result = Specimens::CreateService.call(web_specimen_params)

    if result.success?
      redirect_to specimen_path(result.specimen), notice: t("specimens.flash.created")
    else
      flash.now[:alert] = result.errors.to_sentence
      @specimen = Specimen.new(web_specimen_params.except(:examination_ids, :manual_input))
      @examination_groups = Examination.active.order(:category, :name).group_by(&:category)
      render :new, status: :unprocessable_content
    end
  end

  def show
    @works = @specimen.works.includes(:examination, :examination_results).order(:label_sequence)
  end

  def update
    if @specimen.update(specimen_params)
      redirect_to specimen_path(@specimen), notice: t("specimens.flash.summary_saved")
    else
      redirect_to specimen_path(@specimen), alert: @specimen.errors.full_messages.to_sentence
    end
  end

  def barcode_labels
    @works = @specimen.works.includes(:examination).order(:label_sequence)
    @label_data_collection = @works.map { |work| Works::LabelDataService.call(work) }
    render layout: "print"
  end

  def print_report
    @works = @specimen.works
                      .includes(:examination, examination_results: :reference_rule)
                      .order(:label_sequence)
                      .to_a
    @results_by_work_id = @works.each_with_object({}) do |work, hash|
      hash[work.id] = latest_results_for(work)
    end
    works_with_results  = @works.select { |work| (@results_by_work_id[work.id] || []).any? }
    @grouped_works      = works_with_results.group_by { |w| w.examination.category.presence || "UMUM" }
    @collection_times   = collection_times_by_type(works_with_results)
    @validator          = find_validator(works_with_results)
    render layout: "lab_report"
  end

  def send_report_form
    render layout: false
  end

  def send_report
    email = params[:email]
    if email.blank? || !email.match?(/\A[^@\s]+@[^@\s]+\z/)
      redirect_to specimens_path, alert: t("specimens.flash.invalid_email")
      return
    end

    SpecimenReportJob.perform_later(@specimen.id, email)
    redirect_to specimens_path, notice: t("specimens.flash.report_sent", email: email)
  end

  def generate_ai_summary
    result = Specimens::AiSummaryService.call(@specimen)

    if result.success?
      redirect_to specimen_path(@specimen), notice: t("specimens.flash.ai_summary_generated")
    else
      redirect_to specimen_path(@specimen), alert: result.errors.to_sentence
    end
  end

  def send_whatsapp
    redirect_to specimens_path, notice: t("specimens.flash.whatsapp_sent", order_number: @specimen.order_number)
  end
  private

  # Keep only the latest result per reference rule (skip empty values),
  # scoped to rules matching the specimen's gender.
  def latest_results_for(work)
    work.examination_results
        .where.not(result_value: [ nil, "" ])
        .where(reference_rule_id: ReferenceRule.for_specimen_gender(@specimen.gender).select(:id))
        .order(created_at: :desc, id: :desc)
        .group_by(&:reference_rule_id)
        .transform_values(&:first)
        .values
        .sort_by { |r| r.reference_rule_id }
  end

  def set_specimen
    @specimen = Specimen.find(params[:id])
  end

  def specimen_params
    params.require(:specimen).permit(:ai_summary)
  end

  def web_specimen_params
    params.require(:specimen).permit(
      :patient_id,
      :patient_name,
      :birth_date,
      :gender,
      :medical_record_id,
      :lab_id,
      :department,
      :collection_datetime,
      :dianognes,
      :referring_doctor,
      :affiliation,
      :patient_address,
      :responsible_doctor,
      :manual_input,
      examination_ids: []
    )
  end

  def collection_times_by_type(works)
    works
      .select { |w| w.specimen_type.present? && w.sample_taken_datetime.present? }
      .group_by(&:specimen_type)
      .transform_values { |ws| ws.min_by(&:sample_taken_datetime).sample_taken_datetime }
  end

  def find_validator(works)
    verifier_ids = works.flat_map(&:examination_results).filter_map(&:verified_by).uniq
    User.find_by(id: verifier_ids.first) if verifier_ids.any?
  end
end
