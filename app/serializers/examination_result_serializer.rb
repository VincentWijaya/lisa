class ExaminationResultSerializer < ApplicationSerializer
  def as_json
    {
      id: object.id,
      workId: object.work_id,
      referenceRuleId: object.reference_rule_id,
      resultValue: object.result_value,
      resultUnit: object.result_unit,
      interpretation: object.interpretation,
      source: object.source,
      enteredBy: object.entered_by,
      verifiedBy: object.verified_by,
      verifiedAt: object.verified_at&.iso8601,
      createdAt: object.created_at&.iso8601
    }
  end
end
