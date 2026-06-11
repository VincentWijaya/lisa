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

      @specimen = find_specimen
      return ServiceResult.failure(errors: @errors) if @errors.any?

      ActiveRecord::Base.transaction do
        result_items.each { |item| process_result(item) }
      end

      ServiceResult.success(
        created: @created,
        skipped_count: @skipped_count,
        processed: result_items.length
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
      specimens = Specimen.where(patient_id: params[:patient_id])
                          .where.not(status: Specimen.statuses[:cancelled])
                          .order(created_at: :desc)
                          .limit(2)
                          .to_a

      if specimens.empty?
        @errors << "No active specimen found for patient_id: #{params[:patient_id]}"
        return nil
      end

      if specimens.length > 1
        @errors << "Multiple active specimens found for patient_id: #{params[:patient_id]}"
        return nil
      end

      specimens.first
    end

    def process_result(item)
      reference_rule = reference_rule_for(item)
      return @skipped_count += 1 unless reference_rule

      work = work_for(reference_rule)
      return @skipped_count += 1 unless work

      result = work.examination_results.create!(
        result_value: item[:value].to_s,
        result_unit:  item[:unit].presence,
        reference_rule: reference_rule,
        source: "instrument"
      )
      @created << result
    end

    def reference_rule_for(item)
      loinc = item[:loinc].presence
      local = item[:local_code].presence
      return nil if loinc.nil? && local.nil?

      (loinc && reference_rules_by_loinc[loinc]) ||
        (local && reference_rules_by_local_code[local])
    end

    def work_for(reference_rule)
      works_by_examination_id[reference_rule.examination_id]
    end

    def reference_rules_by_loinc
      @reference_rules_by_loinc ||= index_first_by(
        ReferenceRule.active.where(loinc_code: result_items.filter_map { |item| item[:loinc].presence }.uniq).order(:id),
        :loinc_code
      )
    end

    def reference_rules_by_local_code
      @reference_rules_by_local_code ||= index_first_by(
        ReferenceRule.active.where(local_code: result_items.filter_map { |item| item[:local_code].presence }.uniq).order(:id),
        :local_code
      )
    end

    def works_by_examination_id
      @works_by_examination_id ||= begin
        examination_ids = (reference_rules_by_loinc.values + reference_rules_by_local_code.values).map(&:examination_id).uniq
        if examination_ids.empty?
          {}
        else
          index_first_by(
            @specimen.works.where(examination_id: examination_ids)
                     .where.not(status: Work.statuses[:cancelled])
                     .order(:id),
            :examination_id
          )
        end
      end
    end

    def index_first_by(records, attribute)
      records.each_with_object({}) do |record, index|
        index[record.public_send(attribute)] ||= record
      end
    end

    def result_items
      @result_items ||= Array(params[:results])
    end
  end
end
