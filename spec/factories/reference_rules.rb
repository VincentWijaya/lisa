FactoryBot.define do
  factory :reference_rule do
    association :examination
    sequence(:name) { |n| "Reference Rule #{n}" }
    result_type { "numeric" }
    unit { examination.default_unit || "mg/dL" }
    numeric_low_value { 4.0 }
    numeric_high_value { 6.0 }
    active { true }
    allowed_values { [] }
    normal_values { [] }
    abnormal_values { [] }
    critical_values { [] }
  end
end
