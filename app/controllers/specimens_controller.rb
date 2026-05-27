class SpecimensController < ApplicationController
  before_action :authenticate_user!
  before_action :set_specimen, only: %i[show barcode_labels print_report]

  def index
    scope = Specimen.with_works
                    .filter_by_status(params[:status])
                    .filter_by_patient_name(params[:patient_name])
                    .filter_by_patient_id(params[:patient_id])
                    .filter_by_order_number(params[:order_number])
                    .order(created_at: :desc)
    @pagy, @specimens = pagy(:countless, scope, limit: 10)
  end

  def show
    @works = @specimen.works.includes(:examination, :examination_results).order(:label_sequence)
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
    @grouped_works    = @works.group_by { |w| w.examination.category.presence || "UMUM" }
    @collection_times = collection_times_by_type(@works)
    @validator        = find_validator(@works)
    render layout: "lab_report"
  end
  private

  def set_specimen
    @specimen = Specimen.find(params[:id])
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
