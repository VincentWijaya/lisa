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

      Specimen.transaction do
        specimen = create_specimen!
        create_works!(specimen)
      end

      ServiceResult.success(specimen: specimen)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure(errors: e.record.errors.full_messages)
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
      Specimen.connection.execute("LOCK TABLE specimens IN SHARE ROW EXCLUSIVE MODE")

      Specimen.create!(
        patient_id: params[:patient_id],
        patient_name: params[:patient_name],
        birth_date: params[:birth_date],
        gender: params[:gender],
        medical_record_id: params[:medical_record_id],
        lab_id: params[:lab_id],
        department: params[:department],
        collection_datetime: params[:collection_datetime],
        order_number: next_order_number,
        status: Specimen.statuses[:pending]
      )
    end

    def create_works!(specimen)
      examination_ids.each_with_index do |examination_id, index|
        Works::BarcodeGenerator.new(
          specimen: specimen,
          examination: examinations.fetch(examination_id),
          label_sequence: index + 1
        ).create!
      end
    end

    def next_order_number
      "#{Time.current.strftime('%y%m%d')}#{format('%04d', Specimen.today.count + 1)}"
    end

    def examination_ids
      @examination_ids ||= Array(params[:examination_ids]).map(&:to_i).uniq
    end
  end
end
