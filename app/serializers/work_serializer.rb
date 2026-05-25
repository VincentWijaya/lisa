class WorkSerializer < ApplicationSerializer
  def as_json
    {
      id: object.id,
      barcodeId: object.barcode_id,
      examinationId: object.examination_id,
      status: object.status,
      labelSequence: object.label_sequence,
      specimenType: object.specimen_type,
      testCodesText: object.test_codes_text
    }
  end
end
