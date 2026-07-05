module Api
  module V1
    class AnalyzerController < BaseController
      def ingest
        result = Analyzer::IngestService.call(ingest_params)

        if result.success?
          render json: {
            processed: result.processed,
            results_count: result.results.length,
            skipped_count: result.skipped_count,
            results: result.results.map { |r| ExaminationResultSerializer.serialize(r) }
          }, status: :created
        else
          render json: { errors: result.errors }, status: :unprocessable_content
        end
      end

      private

      def ingest_params
        source = params[:analyzer].presence || params

        source.permit(
          :barcode_id, :gender, :message_datetime, :message_control_id,
          results: [:loinc, :local_code, :test_name, :value, :unit, :reference_range, :flag]
        )
      end
    end
  end
end
