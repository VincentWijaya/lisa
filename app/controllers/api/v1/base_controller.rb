module Api
  module V1
    class BaseController < ActionController::API
      include Pagy::Backend

      before_action :ensure_json_request

      rescue_from ActiveRecord::RecordNotFound do |error|
        render json: { errors: [error.message] }, status: :not_found
      end

      private

      def ensure_json_request
        request.format = :json
      end

      # Clamp page size between 1 and 100, defaulting to 25.
      def pagination_limit
        [(params[:limit] || 25).to_i, 1].max.clamp(1, 100)
      end
    end
  end
end
