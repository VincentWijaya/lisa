module Api
  module V1
    class WorksController < BaseController
      def index
        works = Work.order(created_at: :desc)
        render json: WorkSerializer.serialize_collection(works)
      end

      def show
        work = Work.find(params[:id])
        render json: WorkSerializer.serialize(work)
      end

      def barcode_label
        work = Work.includes(:specimen, :examination).find(params[:id])
        render json: Works::LabelDataService.call(work)
      end
    end
  end
end
