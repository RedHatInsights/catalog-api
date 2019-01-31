FactoryBot.define do
  factory :tenant do
    sequence(:external_tenant) { |n| "#{n}" }

    trait :with_external_tenant do
      external_tenant { '111' }
    end
  end
end
