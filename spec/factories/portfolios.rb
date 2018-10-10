FactoryBot.define do
  factory :portfolio do
    sequence(:name)         { |n| "Portfolio_name_#{n}" }
    sequence(:description)  { |n| "Portfolio_description_#{n}" }

    tenant
    trait :without_tenant do
      tenant_id { nil }
    end
  end
end
