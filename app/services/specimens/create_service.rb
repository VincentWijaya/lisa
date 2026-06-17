module Specimens
  class CreateService
    def self.call(params)
      new(params).call
    end

    def initialize(params)
      @params = params.to_h.deep_symbolize_keys
      @errors = []
    end

    def call
      validate_examinations
      return ServiceResult.failure(errors: errors) if errors.any?

      specimen = nil
      work_result = nil

      Specimen.transaction do
        specimen = create_specimen!
        work_result = create_works!(specimen)
        raise ActiveRecord::Rollback if work_result.failure?
      end

      return ServiceResult.failure(errors: work_result.errors) if work_result&.failure?

      ServiceResult.success(specimen: specimen)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure(errors: e.record.errors.full_messages)
    rescue Specimens::OrderNumberGenerator::DailySequenceExhausted => e
      ServiceResult.failure(errors: [ e.message ])
    end

    private

    attr_reader :params, :errors, :examinations

    def validate_examinations
      ids = examination_ids
      if ids.empty?
        errors << "At least one examination is required"
        return
      end

      @examinations = Examination.active.where(id: ids).index_by(&:id)
      ids.each do |examination_id|
        errors << "Examination #{examination_id} not found or inactive" unless examinations.key?(examination_id)
      end
    end

    def create_specimen!
      Specimen.create!(
        patient_id: params[:patient_id],
        patient_name: params[:patient_name],
        birth_date: params[:birth_date],
        gender: params[:gender],
        medical_record_id: params[:medical_record_id],
        lab_id: params[:lab_id],
        department: params[:department],
        collection_datetime: params[:collection_datetime],
        dianognes: params[:dianognes],
        referring_doctor: params[:referring_doctor],
        affiliation: params[:affiliation],
        patient_address: params[:patient_address],
        responsible_doctor: params[:responsible_doctor],
        order_number: next_order_number,
        status: Specimen.statuses[:pending]
      )
    end

    def create_works!(specimen)
      Works::WorkCreationService.call(specimen: specimen, examinations: ordered_examinations)
    end

    def next_order_number
      Specimens::OrderNumberGenerator.call
    end

    def examination_ids
      @examination_ids ||= Array(params[:examination_ids]).map(&:to_i).uniq
    end

    def ordered_examinations
      @ordered_examinations ||= examination_ids.filter_map { |examination_id| examinations[examination_id] }
    end
  end
end
