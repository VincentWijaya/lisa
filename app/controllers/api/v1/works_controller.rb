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
    end
  end
end
