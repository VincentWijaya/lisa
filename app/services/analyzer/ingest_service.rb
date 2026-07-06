module Analyzer
  class IngestService
    def self.call(params)
      new(params).call
    end

    def initialize(params)
      @params = params.to_h.symbolize_keys
      @errors = []
      @created_count = 0
      @skipped_count = 0
      @processed_records = []
    end

    def call
      validate_inputs
      return ServiceResult.failure(errors: @errors) if @errors.any?

      @specimen = find_specimen
      return ServiceResult.failure(errors: @errors) if @errors.any?

      preload_context
      reference_rules_by_loinc
      reference_rules_by_local_code

      ActiveRecord::Base.transaction do
        result_items.each { |item| process_result(item) }
      end

      ExaminationResults::ComputedResultRecomputer.call(specimen: @specimen)

      ServiceResult.success(
        created: @created_count,
        skipped_count: @skipped_count,
        processed: result_items.length,
        results: @processed_records
      )
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure(errors: e.record.errors.full_messages)
    end

    private

    attr_reader :params

    def validate_inputs
      @errors << "barcode_id is required" if params[:barcode_id].blank?
      @errors << "results must be an array" unless params[:results].is_a?(Array)
    end

    def find_specimen
      work = Work.where(barcode_id: params[:barcode_id].to_s.strip)
                 .where.not(status: "cancelled")
                 .order(id: :desc)
                 .limit(2)
                 .includes(:specimen)
                 .to_a

      if work.empty?
        @errors << "No active work found for barcode_id: #{params[:barcode_id]}"
        return nil
      end

      if work.length > 1
        @errors << "Multiple active works found for barcode_id: #{params[:barcode_id]}"
        return nil
      end

      @work = work.first
      @work.specimen
    end

    def preload_context
      works = @specimen.works.where.not(status: "cancelled").order(id: :desc).to_a
      work_ids = works.map(&:id)

      @works_by_code = {}
      works.each do |work|
        next if work.test_codes_text.blank?

        codes = work.test_codes_text.split(";").map { |c| c.strip.downcase }.reject(&:empty?)
        codes.each do |code|
          @works_by_code[code] ||= work
        end
      end

      existing_results = ExaminationResult.where(work_id: work_ids).to_a
      @results_cache = existing_results.each_with_object({}) do |res, hash|
        hash[[ res.work_id, res.reference_rule_id ]] = res
      end
    end

    def process_result(item)
      reference_rule = reference_rule_for(item)
      return @skipped_count += 1 unless reference_rule

      exam_code = reference_rule.examination.code&.downcase
      return @skipped_count += 1 if exam_code.nil?

      work = @works_by_code[exam_code]
      return @skipped_count += 1 unless work

      result = @results_cache[[ work.id, reference_rule.id ]] || ExaminationResult.new(
        work_id: work.id, 
        reference_rule_id: reference_rule.id
      )

      result.assign_attributes(
        result_value: item["value"].to_s,
        result_unit:  item["unit"].presence,
        source: "instrument"
      )

      result.interpretation = reference_rule.interpretation_for(result.result_value)

      @created_count += 1 if result.new_record?

      result.save!
      @processed_records << result
    end

    def reference_rule_for(item)
      loinc = item["loinc"].presence
      local = item["local_code"].presence
      return nil if loinc.nil? && local.nil?

      candidates = []
      candidates.concat(reference_rules_by_loinc[loinc]   || []) if loinc
      candidates.concat(reference_rules_by_local_code[local] || []) if local
      return nil if candidates.empty?

      ReferenceRule.best_for_specimen(candidates.uniq, @specimen.gender)
    end

    def reference_rules_by_loinc
      @reference_rules_by_loinc ||= ReferenceRule
                                   .where(active: [ true, 1 ])
                                   .includes(:examination)
                                   .where(loinc_code: loinc_ids)
                                   .order(:id)
                                   .group_by(&:loinc_code)
    end

    def reference_rules_by_local_code
      @reference_rules_by_local_code ||= ReferenceRule
                                        .where(active: [ true, 1 ])
                                        .includes(:examination)
                                        .where(local_code: local_ids)
                                        .order(:id)
                                        .group_by(&:local_code)
    end

    def loinc_ids
      @loinc_ids ||= result_items.filter_map { |item| item["loinc"].presence }.uniq
    end

    def local_ids
      @local_ids ||= result_items.filter_map { |item| item["local_code"].presence }.uniq
    end

    def result_items
      @result_items ||= Array(params[:results]).map(&:with_indifferent_access)
    end
  end
end
