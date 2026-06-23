module Api
  module V1
    class ExaminationsController < BaseController
      def index
        scope = Examination.order(:name)
        pagy, examinations = pagy(:countless, scope, limit: pagination_limit)
        response.headers.merge!(pagy.headers_hash)
        render json: {
          data: ExaminationSerializer.serialize_collection(examinations),
          pagination: pagy_metadata(pagy)
        }
      end
    end
  end
end
