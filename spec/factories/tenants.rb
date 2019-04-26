FactoryBot.define do
  factory :tenant do
    sequence(:external_tenant)

    trait :with_external_tenant do
      external_tenant { "0369233" }
    end
  end
end
