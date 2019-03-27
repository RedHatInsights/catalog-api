FactoryBot.define do
  factory :portfolio_item do
    sequence(:name)                 { |n| "PortfolioItem_name_#{n}" }
    sequence(:description)          { |n| "PortfolioItem_description_#{n}" }
    sequence(:service_offering_ref) { |n| (rand(0) + n).to_s }
    sequence(:service_offering_source_ref) { |n| (rand(0) + n).to_s }
    owner { "wilma" }

    tenant

    trait :with_portfolio do
      after(:create) do |portfolio, _evaluator|
        create_list(:portfolio_item, :portfolios => [portfolio])
      end
    end

    trait :without_tenant do
      tenant_id { nil }
    end
  end
end
