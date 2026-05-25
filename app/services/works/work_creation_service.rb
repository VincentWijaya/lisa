module Works
  class WorkCreationService
    def self.call(specimen:, examinations:)
      new(specimen: specimen, examinations: examinations).call
    end

    def initialize(specimen:, examinations:)
      @specimen = specimen
      @examinations = Array(examinations)
      @errors = []
    end

    def call
      validate_group_specimen_types
      return ServiceResult.failure(errors: errors) if errors.any?

      works = grouped_examinations.each_with_index.map do |grouped_examinations, index|
        Works::BarcodeGenerator.new(
          specimen: specimen,
          examinations: grouped_examinations,
          label_sequence: index + 1
        ).create!
      end

      ServiceResult.success(works: works)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure(errors: e.record.errors.full_messages)
    end

    private

    attr_reader :specimen, :examinations, :errors

    def grouped_examinations
      @grouped_examinations ||= examinations.each_with_object({}) do |examination, groups|
        key = examination.label_group.present? ? "group:#{examination.label_group}" : "exam:#{examination.id}"
        groups[key] ||= []
        groups[key] << examination
      end.values
    end

    def validate_group_specimen_types
      grouped_examinations.each do |group|
        specimen_types = group.map(&:specimen_type).compact_blank.uniq
        next if specimen_types.size <= 1

        errors << "Grouped examinations must share the same specimen type for label group #{group.first.label_group}"
      end
    end
  end
end
