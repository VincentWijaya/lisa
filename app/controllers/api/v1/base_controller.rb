module Api
  module V1
    class BaseController < ActionController::API
      before_action :ensure_json_request

      rescue_from ActiveRecord::RecordNotFound do |error|
        render json: { errors: [error.message] }, status: :not_found
      end

      private

      def ensure_json_request
        request.format = :json
      end
    end
  end
end
