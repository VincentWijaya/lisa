FactoryBot.define do
  factory :specimen do
    sequence(:patient_id) { |n| "PAT#{n}" }
    patient_name { "Jane Doe" }
    birth_date { Date.new(1990, 5, 15) }
    gender { "Female" }
    sequence(:medical_record_id) { |n| "MR#{n}" }
    lab_id { "LAB123" }
    sequence(:order_number) { |n| "#{Date.current.strftime('%y%m%d')}#{format('%04d', n)}" }
    department { "Emergency" }
    collection_datetime { Time.zone.parse("2026-05-25 10:30:00") }
    status { "pending" }
    referring_doctor { nil }
    affiliation { nil }
    patient_address { nil }
    responsible_doctor { nil }
  end
end
