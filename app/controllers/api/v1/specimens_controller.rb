module Api
  module V1
    class SpecimensController < BaseController
      require "pagy/extras/countless"

      def index
        scope = Specimen.includes(:works).order(created_at: :desc)
        last_modified = scope.maximum(:updated_at) || Time.at(0)
        return unless stale?(last_modified: last_modified, public: false)

        pagy, specimens = pagy_countless(scope, limit: pagination_limit)
        pagy_headers_merge(pagy)
        render json: {
          data: SpecimenSerializer.serialize_collection(specimens),
          pagination: pagy_metadata(pagy)
        }
      end

      def show
        specimen = Specimen.includes(:works).find(params[:id])
        return unless stale?(specimen, public: false)

        render json: SpecimenSerializer.serialize(specimen)
      end

      def create
        result = Specimens::CreateService.call(specimen_params)

        if result.success?
          render json: SpecimenSerializer.serialize(result.specimen), status: :created
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      private

      def specimen_params
        raw_params = params.to_unsafe_h.except("controller", "action", "format")
        nested_params = raw_params.delete("specimen")
        merged_params = nested_params.is_a?(Hash) ? nested_params.merge(raw_params) : raw_params

        ActionController::Parameters.new(merged_params).permit(
          :patient_id,
          :patient_name,
          :birth_date,
          :gender,
          :medical_record_id,
          :lab_id,
          :department,
          :collection_datetime,
          examination_ids: []
        )
      end
    end
  end
end
