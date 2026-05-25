FactoryBot.define do
  factory :work do
    association :specimen
    association :examination
    sequence(:barcode_id) { |n| "#{Date.current.strftime('%y%m%d')}#{format('%04d', n)}-01" }
    label_sequence { 1 }
    manual_input { false }
    specimen_type { examination.specimen_type }
    test_codes_text { "#{examination.code};" }
    sample_taken_datetime { specimen.collection_datetime }
    status { "pending" }
  end
end
