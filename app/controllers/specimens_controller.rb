class SpecimensController < ApplicationController
  def barcode_labels
    @specimen = Specimen.find(params[:id])
    @works = @specimen.works.includes(:examination).order(:label_sequence)
    @label_data_collection = @works.map { |work| Works::LabelDataService.call(work) }
    render layout: "print"
  end
end
