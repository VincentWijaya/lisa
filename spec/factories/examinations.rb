FactoryBot.define do
  factory :examination do
    sequence(:name) { |n| "Examination #{n}" }
    sequence(:code) { |n| "EXAM#{n}" }
    description { "Routine lab examination" }
    default_unit { "mg/dL" }
    default_result_type { "numeric" }
    status { "active" }
    specimen_type { "Blood" }
    label_group { nil }
  end
end
