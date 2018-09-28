FactoryBot.define do
  factory :portfolio_item do
    sequence(:name)         { |n| "PortfolioItem_name_#{n}" }
    sequence(:description)  { |n| "PortfolioItem_description_#{n}" }
  end
end
