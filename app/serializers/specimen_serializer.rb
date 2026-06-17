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
      dianognes: object.dianognes,
      referringDoctor: object.referring_doctor,
      affiliation: object.affiliation,
      patientAddress: object.patient_address,
      responsibleDoctor: object.responsible_doctor,
      works: WorkSerializer.serialize_collection(ordered_works)
    }
  end

  private

  def ordered_works
    if object.association(:works).loaded?
      object.works.sort_by { |work| [ work.label_sequence, work.id ] }
    else
      object.works.order(:label_sequence)
    end
  end
end
