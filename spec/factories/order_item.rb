FactoryBot.define do
  factory :order_item do
    service_parameters { {'name' => 'fred'} }
    provider_control_parameters { {'namespace' => 'barney'} }
    service_plan_ref { "something" }
    count { 1 }
  end
end
