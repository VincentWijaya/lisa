module Api
  module V1
    class SpecimensController < BaseController
      def index
        specimens = Specimen.includes(:works).order(created_at: :desc)
        render json: SpecimenSerializer.serialize_collection(specimens)
      end

      def show
        specimen = Specimen.includes(:works).find(params[:id])
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
        base_params = params[:specimen].present? ? params.require(:specimen) : params
        base_params.permit(
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
