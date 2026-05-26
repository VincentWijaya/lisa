class SpecimensController < ApplicationController
  require "pagy/extras/countless"

  before_action :authenticate_user!
  before_action :set_specimen, only: %i[show barcode_labels]

  def index
    scope = Specimen.with_works
                    .filter_by_status(params[:status])
                    .filter_by_patient_name(params[:patient_name])
                    .filter_by_patient_id(params[:patient_id])
                    .filter_by_order_number(params[:order_number])
                    .order(created_at: :desc)
    @pagy, @specimens = pagy_countless(scope, limit: 10)
  end

  def show
    @works = @specimen.works.includes(:examination, :examination_results).order(:label_sequence)
  end

  def barcode_labels
    @works = @specimen.works.includes(:examination).order(:label_sequence)
    @label_data_collection = @works.map { |work| Works::LabelDataService.call(work) }
    render layout: "print"
  end

  private

  def set_specimen
    @specimen = Specimen.find(params[:id])
  end
end
