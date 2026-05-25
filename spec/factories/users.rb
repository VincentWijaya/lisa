FactoryBot.define do
  factory :user do
    name     { Faker::Name.name }
    email    { Faker::Internet.unique.email }
    password { "Password@123" }
    active   { true }

    trait :inactive do
      active { false }
    end

    trait :admin do
      after(:create) { |u| u.add_role(:admin) }
    end

    trait :lab_supervisor do
      after(:create) { |u| u.add_role(:lab_supervisor) }
    end

    trait :lab_technician do
      after(:create) { |u| u.add_role(:lab_technician) }
    end

    trait :doctor do
      after(:create) { |u| u.add_role(:doctor) }
    end
  end
end
