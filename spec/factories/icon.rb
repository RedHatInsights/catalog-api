FactoryBot.define do
  factory :icon, :traits => [:has_tenant] do
    sequence(:source_ref) { |n| "source_ref_#{n}" }
    sequence(:source_id)  { |n| "source_id_#{n}" }

    image

    iconable { create(:portfolio_item) }
  end
end
