module Api
  module V1
    class AnalyzerController < BaseController
      def ingest
        result = Analyzer::IngestService.call(ingest_params)

        if result.success?
          render json: {
            processed: result.processed,
            created: result.created.length,
            skipped: result.skipped_count,
            results: result.created.map { |r| ExaminationResultSerializer.serialize(r) }
          }, status: :created
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      private

      def ingest_params
        params.permit(
          :patient_id, :gender, :message_datetime, :message_control_id,
          results: [:loinc, :local_code, :test_name, :value, :unit, :reference_range, :flag]
        )
      end
    end
  end
end
