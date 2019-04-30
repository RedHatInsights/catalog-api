FactoryBot.define do
  factory :portfolio do
    sequence(:name)         { |n| "Portfolio_name_#{n}" }
    sequence(:description)  { |n| "Portfolio_description_#{n}" }
    sequence(:image_url)    { |n| "https://portfolio#{n}.com/image/#{n}" }
    enabled                 { "true" }
    owner                   { default_username }
  end
end
