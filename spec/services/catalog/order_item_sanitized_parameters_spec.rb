describe Catalog::OrderItemSanitizedParameters do
  include ServiceSpecHelper

  Plan = Struct.new(:name, :id, :description, :create_json_schema)
  let(:plan) { Plan.new("Plan A", "1", "Plan A", json_schema) }
  let(:api_instance) { double(:api_instance) }
  let(:service_plan_ref) { "777" }
  let(:oisp) do
    with_modified_env :TOPOLOGY_SERVICE_URL => 'http://www.example.com' do
      Catalog::OrderItemSanitizedParameters.new(params)
    end
  end

  let(:order_item) do
    create(:order_item, :portfolio_item_id           => 100,
                        :order_id                    => 45,
                        :service_plan_ref            => service_plan_ref,
                        :service_parameters          => service_parameters,
                        :provider_control_parameters => { 'a' => 1 },
                        :count                       => 1)
  end

  let(:service_parameters) do
    { 'user'     => 'Fred Flintstone',
      'password' => 'Yabba Dabba Doo',
      'salary'   => 10_000_000,
      'newpwd'   => 'Yabba Dabba Two',
      'db_name'  => 'Slate Rocking Company' }
  end

  let(:params) do
    ActionController::Parameters.new('order_item_id' => order_item.id)
  end

  let(:topological_inventory) do
    class_double(TopologicalInventory).as_stubbed_const(:transfer_nested_constants => true)
  end

  describe "#process" do
    before do
      allow(topological_inventory).to receive(:call).and_yield(api_instance)
      allow(api_instance).to receive(:show_service_plan).and_return(plan)
      allow(plan).to receive(:create_json_schema).and_return(json_schema)
    end

    context "ddf parameters" do
      let(:json_schema) do
        {
          :schema => {
            :fields => [
              {
                :name         => "Totally not a pass",
                :type         => "password",
                :label        => "Totally not a pass",
                :component    => "text-field",
                :helperText   => "",
                :isRequired   => true,
                :initialValue => ""
              },
              {
                :name         => "most_important_var1",
                :label        => "secret field 1",
                :component    => "textarea-field",
                :helperText   => "Has no effect on anything, ever.",
                :initialValue => ""
              },
              {
                :name         => "token idea",
                :label        => "field 1",
                :component    => "textarea-field",
                :helperText   => "Don't look.",
                :initialValue => ""
              }
            ]
          }
        }
      end

      it "success scenario" do
        expect(api_instance).to receive(:show_service_plan)
          .with(order_item.service_plan_ref)
          .and_return(plan)

        result = oisp.process

        expect(result.values.select { |v| v == described_class::MASKED_VALUE }.count).to eq(3)
      end

      it "failure scenario" do
        expect(api_instance).to receive(:show_service_plan)
          .with(order_item.service_plan_ref)
          .and_raise(TopologicalInventoryApiClient::ApiError.new("Kaboom"))

        expect { oisp.process }.to raise_error(StandardError)
      end
    end
  end
end
