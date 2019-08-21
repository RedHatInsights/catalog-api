describe Catalog::SubmitOrder do
  let(:service_offering_ref) { "998" }
  let(:service_plan_ref) { "991" }
  let(:order) { create(:order) }
  let(:service_parameters) { { 'var1' => 'Fred', 'var2' => 'Wilma' } }
  let(:provider_control_parameters) { { 'namespace' => 'Bedrock' } }
  let!(:order_item) do
    create(:order_item, :portfolio_item_id           => portfolio_item.id,
                        :service_parameters          => service_parameters,
                        :service_plan_ref            => service_plan_ref,
                        :provider_control_parameters => provider_control_parameters,
                        :order_id                    => order.id,
                        :count                       => 1,
                        :context                     => default_request)
  end
  let(:portfolio_item) { create(:portfolio_item, :service_offering_ref => service_offering_ref, :service_offering_source_ref => "17") }
  let(:portfolio_item_id) { portfolio_item.id.to_s }
  let(:params) { order.id.to_s }
  let(:submit_order) { described_class.new(params) }
  let(:api_instance) { double }
  let(:ti_class) { class_double("TopologicalInventory").as_stubbed_const(:transfer_nested_constants => true) }
  let(:task) { double("task") }
  let(:args) { an_instance_of(TopologicalInventoryApiClient::OrderParameters) }
  let(:validater) { instance_double(Catalog::ValidateSource) }
  let(:valid_source) { true }

  before do
    allow(ti_class).to receive(:call).and_yield(api_instance)
    allow(Catalog::ValidateSource).to receive(:new).with(portfolio_item.service_offering_source_ref).and_return(validater)
    allow(validater).to receive(:process).and_return(validater)
    allow(validater).to receive(:valid).and_return(valid_source)
  end

  context "when the source is valid" do
    it "fetches the array of plans" do
      allow(task).to receive(:task_id).and_return("100")
      allow(api_instance).to receive(:order_service_plan).with(service_plan_ref, args).and_return(task)

      expect(submit_order.process.order.order_items.first.topology_task_ref).to eq("100")
    end
  end

  context "when the source is not valid" do
    let(:valid_source) { false }

    it "throws unauthorized" do
      ManageIQ::API::Common::Request.with_request(default_request) do
        expect { submit_order.process }.to raise_error(Catalog::NotAuthorized)
      end
    end
  end

  context "invalid portfolio item" do
    let(:params) { 333 }
    it "raises exception" do
      expect { submit_order.process }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
