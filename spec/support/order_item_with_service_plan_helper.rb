RSpec.shared_context "uses an order item with raw service parameters set" do
  let(:service_plan_show_response) do
    TopologicalInventoryApiClient::ServicePlan.new(
      :name               => "Plan A",
      :id                 => "1",
      :description        => "Plan A",
      :create_json_schema => {:schema => {:fields => [{:name => "var1"}, {:name => "var2"}]}}
    )
  end

  let(:order_item) do
    create(
      :order_item_with_callback,
      :portfolio_item              => portfolio_item,
      :service_parameters          => service_parameters,
      :service_plan_ref            => service_plan_ref,
      :provider_control_parameters => provider_control_parameters,
      :order_id                    => order.id,
      :count                       => 1,
      :context                     => default_request,
      :process_scope               => 'product',
      :process_sequence            => 1
    ).tap do |item|
      item.update(:state => 'Approved')
    end
  end

  before do
    stub_request(:get, topological_url("service_plans/#{service_plan_ref}"))
      .to_return(:status => 200, :body => service_plan_show_response.to_json, :headers => default_headers)

    order_item
  end
end
