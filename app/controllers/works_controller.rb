class WorksController < ApplicationController
  def barcode_label
    @work = Work.includes(:specimen, :examination).find(params[:id])
    @label_data = Works::LabelDataService.call(@work)
    render layout: "print"
  end
end
