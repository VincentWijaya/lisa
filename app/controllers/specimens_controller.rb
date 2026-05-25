class SpecimensController < ApplicationController
  before_action :authenticate_user!
  before_action :set_specimen, only: %i[show barcode_labels]

  def index
    scope = Specimen.with_works.order(created_at: :desc)
    @pagy, @specimens = pagy(scope, limit: 25)
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
