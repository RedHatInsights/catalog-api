FactoryBot.define do
  factory :tenant do
    sequence(:ref_id)         { |n| "#{n}" }

    trait :with_external_tenant do
      ref_id { '111' }
    end
  end
end
