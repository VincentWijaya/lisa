module Works
  class LabelDataService
    def self.call(work)
      new(work).as_json
    end

    def initialize(work)
      @work = work
    end

    def as_json
      {
        workId: work.id,
        specimenId: specimen.id,
        specimenType: work.specimen_type,
        collectionDatetime: formatted_collection_datetime,
        barcodeId: work.barcode_id,
        patientName: specimen.patient_name.to_s.upcase,
        medicalRecordId: specimen.medical_record_id,
        ageYears: specimen.age_in_years,
        gender: specimen.gender,
        birthDate: formatted_birth_date,
        testCodesText: work.examination&.category,
        department: specimen.department
      }
    end

    private

    attr_reader :work

    def specimen
      @specimen ||= work.specimen
    end

    def formatted_collection_datetime
      work.sample_taken_datetime&.strftime("%d-%m-%Y %H:%M:%S")
    end

    def formatted_birth_date
      specimen.birth_date&.strftime("%d-%m-%Y")
    end
  end
end
