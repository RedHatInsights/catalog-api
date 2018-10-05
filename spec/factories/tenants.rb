FactoryBot.define do
  factory :tenant do
    sequence(:ref_id)         { |n| "#{n}" }
  end
end
