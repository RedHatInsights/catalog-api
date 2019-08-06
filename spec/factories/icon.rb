FactoryBot.define do
  factory :icon do
    sequence(:source_ref) { |n| "source_ref_#{n}" }
    sequence(:source_id)  { |n| "source_id_#{n}" }
    sequence(:image_id)
  end
end
