module ExaminationResults
  class UpsertForWorkService
    def self.call(work:, params:, entered_by:)
      new(work: work, params: params, entered_by: entered_by).call
    end

    def initialize(work:, params:, entered_by:)
      @work = work
      @params = params.to_h.deep_symbolize_keys
      @entered_by = entered_by
      @errors = []
      @upserted_count = 0
    end

    def call
      return ServiceResult.failure(errors: ["Results can only be saved for pending or validated works"]) unless work.pending? || work.validated?

      ExaminationResult.transaction do
        work.lock!
        rows = upsertable_rows

        raise ActiveRecord::Rollback if errors.any?

        bulk_update(rows.select { |row| row[:existing_result].present? })
        bulk_insert(rows.reject { |row| row[:existing_result].present? })
      end

      return ServiceResult.failure(errors: errors) if errors.any?

      recompute_formulas
      ServiceResult.success(upserted_count: upserted_count)
    end

    private

    attr_reader :work, :params, :entered_by, :errors
    attr_accessor :upserted_count

    def recompute_formulas
      ComputedResultRecomputer.call(specimen: work.specimen, entered_by: entered_by)
    end

    def result_rows
      Array(params.fetch(:results, {}).values).map { |row| row.to_h.deep_symbolize_keys }
    end

    def upsertable_rows
      result_rows.filter_map do |row|
        reference_rule = find_reference_rule(row[:reference_rule_id])
        next unless reference_rule

        existing_result = existing_result_for(reference_rule)
        result_value = row[:result_value].to_s.strip
        next if result_value.blank? && existing_result.blank?

        source = row[:source].presence || existing_result&.source || ExaminationResult.sources[:manual]
        validate_row(reference_rule, result_value, source)

        {
          existing_result: existing_result,
          reference_rule: reference_rule,
          result_value: result_value,
          result_unit: row[:result_unit].presence || reference_rule.unit.presence || work.examination.default_unit,
          source: source,
          interpretation: reference_rule.interpretation_for(result_value)
        }
      end
    end

    def find_reference_rule(id)
      reference_rules_by_id[id.to_i].tap do |reference_rule|
        errors << "Reference rule #{id} not found for this work" if reference_rule.nil?
      end
    end

    def validate_row(reference_rule, result_value, source)
      errors << "Source #{source} is not valid" unless ExaminationResult.sources.key?(source)

      if result_value.blank?
        errors << "#{reference_rule.name}: Result value can't be blank"
      elsif reference_rule.allowed_values.present? && !reference_rule.allowed_values.include?(result_value)
        errors << "#{reference_rule.name}: Result value must be one of: #{reference_rule.allowed_values.join(', ')}"
      end
    end

    def bulk_update(rows)
      return if rows.empty?

      now = Time.current
      ids = rows.map { |row| row[:existing_result].id }
      assignments = %i[result_value result_unit source interpretation].map do |column|
        "#{connection.quote_column_name(column)} = #{case_statement(rows, column)}"
      end
      assignments << "updated_at = #{connection.quote(now)}"

      connection.execute(<<~SQL.squish)
        UPDATE #{connection.quote_table_name(ExaminationResult.table_name)}
        SET #{assignments.join(", ")}
        WHERE id IN (#{ids.join(", ")})
      SQL
      self.upserted_count += rows.size
    end

    def bulk_insert(rows)
      return if rows.empty?

      now = Time.current
      ExaminationResult.insert_all!(
        rows.map do |row|
          {
            work_id: work.id,
            reference_rule_id: row[:reference_rule].id,
            result_value: row[:result_value],
            result_unit: row[:result_unit],
            source: row[:source],
            interpretation: row[:interpretation],
            entered_by: entered_by,
            created_at: now,
            updated_at: now
          }
        end
      )
      self.upserted_count += rows.size
    end

    def case_statement(rows, column)
      cases = rows.map do |row|
        id = row[:existing_result].id
        value = row[column]
        "WHEN #{id} THEN #{connection.quote(value)}"
      end.join(" ")
      "CASE id #{cases} END"
    end

    def connection
      ExaminationResult.connection
    end

    def existing_result_for(reference_rule)
      existing_results_by_reference_rule[reference_rule.id]
    end

    def existing_results_by_reference_rule
      @existing_results_by_reference_rule ||= work.examination_results
                                                .where(reference_rule_id: reference_rules_by_id.keys)
                                                .order(created_at: :desc)
                                                .group_by(&:reference_rule_id)
                                                .transform_values(&:first)
    end

    def reference_rules_by_id
      @reference_rules_by_id ||= ReferenceRule.active
                                             .where(examination_id: eligible_examination_ids)
                                             .for_specimen_gender(work.specimen.gender)
                                             .index_by(&:id)
    end

    def eligible_examination_ids
      @eligible_examination_ids ||= begin
        codes = work.test_codes_text.to_s.split(";").map(&:strip).reject(&:blank?)
        ids = Examination.where(code: codes).pluck(:id)
        ids.presence || [work.examination_id]
      end
    end
  end
end
