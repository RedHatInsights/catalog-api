FactoryBot.define do
  factory :order, :traits => [:has_owner, :has_tenant]
end
