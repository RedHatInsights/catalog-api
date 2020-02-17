FactoryBot.define do
  factory :order_item, :traits => [:has_owner, :has_tenant] do
    service_parameters { {'name' => 'fred'} }
    provider_control_parameters { {'namespace' => 'barney'} }
    service_plan_ref { "something" }
    count { 1 }
    insights_request_id { "insights-request-id" }

    after(:build) { |order_item| order_item.class.skip_callback(:save, :before, :sanitize_parameters, :raise => false) }

    factory :order_item_with_callback do
      after(:create) { |order_item| order_item.send(:sanitize_parameters); order_item.save! }
    end

    order
    portfolio_item
  end
end
