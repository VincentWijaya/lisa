FactoryBot.define do
  factory :examination_result do
    association :work
    result_value { "5.1" }
    result_unit { work.examination.default_unit || "mg/dL" }
    source { "manual" }
    interpretation { nil }
    reference_rule { nil }
  end
end
