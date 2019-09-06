FactoryBot.define do
  factory :order_item, :traits => [:has_owner, :has_tenant] do
    service_parameters { {'name' => 'fred'} }
    provider_control_parameters { {'namespace' => 'barney'} }
    service_plan_ref { "something" }
    count { 1 }
    insights_request_id { "insights-request-id" }

    order
    portfolio_item
  end
end
