module Api
  module V1
    class WorksController < BaseController
      def index
        scope = Work.order(created_at: :desc)
        pagy, works = pagy(scope, limit: pagination_limit)
        pagy_headers_merge(pagy)
        render json: {
          data: WorkSerializer.serialize_collection(works),
          pagination: pagy_metadata(pagy)
        }
      end

      def show
        work = Work.find(params[:id])
        render json: WorkSerializer.serialize(work)
      end

      def validate
        transition_result = Works::ValidateService.call(work: work)
        render_transition_response(transition_result)
      end

      def verify
        transition_result = Works::VerifyService.call(work: work)
        render_transition_response(transition_result)
      end

      def cancel
        transition_result = Works::CancelService.call(work: work)
        render_transition_response(transition_result)
      end

      def results
        result = ExaminationResults::CreateService.call(work: work, params: result_params)

        if result.success?
          render json: ExaminationResultSerializer.serialize(result.examination_result), status: :created
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      def barcode_label
        render json: Works::LabelDataService.call(work)
      end

      private

      def work
        @work ||= Work.includes(:specimen, :examination).find(params[:id])
      end

      def result_params
        params.permit(:result_value, :result_unit, :reference_rule_id, :source, :entered_by, :verified_by, :verified_at)
      end

      def render_transition_response(result)
        if result.success?
          render json: WorkSerializer.serialize(result.work)
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end
    end
  end
end
