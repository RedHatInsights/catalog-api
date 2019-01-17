FactoryBot.define do
  factory :portfolio_item do
    sequence(:name)                 { |n| "PortfolioItem_name_#{n}" }
    sequence(:description)          { |n| "PortfolioItem_description_#{n}" }
    sequence(:service_offering_ref) { |n| (rand(0) + n).to_s }
    sequence(:service_offering_source_ref) { |n| (rand(0) + n).to_s }
  end
end
