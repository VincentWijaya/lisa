class ExaminationSerializer < ApplicationSerializer
  def as_json
    {
      id: object.id,
      code: object.code,
      name: object.name,
      category: object.category,
      labelGroup: object.label_group,
      specimenType: object.specimen_type,
      defaultResultType: object.default_result_type,
      defaultUnit: object.default_unit,
      status: object.status
    }
  end
end
