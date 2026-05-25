class SpecimenSerializer < ApplicationSerializer
  def as_json
    {
      id: object.id,
      patientId: object.patient_id,
      patientName: object.patient_name,
      birthDate: object.birth_date&.iso8601,
      gender: object.gender,
      medicalRecordId: object.medical_record_id,
      labId: object.lab_id,
      orderNumber: object.order_number,
      status: object.status,
      works: WorkSerializer.serialize_collection(object.works.order(:label_sequence))
    }
  end
end
