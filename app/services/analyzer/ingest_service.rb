module Analyzer
  class IngestService
    def self.call(params)
      new(params).call
    end

    def initialize(params)
      @params = params.to_h.deep_symbolize_keys
      @errors = []
      @created = []
      @skipped_count = 0
    end

    def call
      validate_inputs
      return ServiceResult.failure(errors: @errors) if @errors.any?

      specimen = find_specimen
      return ServiceResult.failure(errors: @errors) if @errors.any?

      ActiveRecord::Base.transaction do
        Array(@params[:results]).each { |item| process_result(specimen, item) }
      end

      ServiceResult.success(
        created: @created,
        skipped_count: @skipped_count,
        processed: Array(@params[:results]).length
      )
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure(errors: e.record.errors.full_messages)
    end

    private

    attr_reader :params

    def validate_inputs
      @errors << "patient_id is required" if params[:patient_id].blank?
      @errors << "results must be an array" unless params[:results].is_a?(Array)
    end

    def find_specimen
      specimen = Specimen.where(patient_id: params[:patient_id])
                         .where.not(status: "cancelled")
                         .order(created_at: :desc)
                         .first
      @errors << "No active specimen found for patient_id: #{params[:patient_id]}" if specimen.nil?
      specimen
    end

    def process_result(specimen, item)
      reference_rule = find_reference_rule(item)
      return @skipped_count += 1 unless reference_rule

      work = find_work(specimen, reference_rule)
      return @skipped_count += 1 unless work

      result = work.examination_results.create!(
        result_value: item[:value].to_s,
        result_unit:  item[:unit].presence,
        reference_rule: reference_rule,
        source: "instrument"
      )
      @created << result
    end

    def find_reference_rule(item)
      loinc = item[:loinc].presence
      local = item[:local_code].presence
      return nil if loinc.nil? && local.nil?

      rule = ReferenceRule.active.find_by(loinc_code: loinc) if loinc
      rule ||= ReferenceRule.active.find_by(local_code: local) if local
      rule
    end

    def find_work(specimen, reference_rule)
      specimen.works.where(examination_id: reference_rule.examination_id)
                    .where.not(status: "cancelled")
                    .first
    end
  end
end
