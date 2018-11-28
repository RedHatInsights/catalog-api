FactoryBot.define do
  factory :authentication do
    sequence(:name) { |n| "Authentication_name_#{n}" }
  end
end
