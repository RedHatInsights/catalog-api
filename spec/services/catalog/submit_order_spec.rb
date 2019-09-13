describe Catalog::SubmitOrder do
  let(:service_offering_ref) { "998" }
  let(:service_plan_ref) { "991" }
  let(:order) { create(:order) }
  let(:service_parameters) { { 'var1' => 'Fred', 'var2' => 'Wilma' } }
  let(:provider_control_parameters) { { 'namespace' => 'Bedrock' } }
  let!(:order_item) do
    create(:order_item, :portfolio_item              => portfolio_item,
                        :service_parameters          => service_parameters,
                        :service_plan_ref            => service_plan_ref,
                        :provider_control_parameters => provider_control_parameters,
                        :order_id                    => order.id,
                        :count                       => 1,
                        :context                     => default_request)
  end
  let(:portfolio_item) do
    create(:portfolio_item, :service_offering_ref => service_offering_ref, :service_offering_source_ref => "17")
  end
  let(:submit_order) { described_class.new(params) }
  let(:validater) { instance_double(Catalog::ValidateSource) }
  let(:validity) { true }

  around do |example|
    with_modified_env(:TOPOLOGICAL_INVENTORY_URL => "http://localhost", :SOURCES_URL => "http://localhost") do
      example.call
    end
  end

  before do
    allow(Catalog::ValidateSource).to receive(:new).with(portfolio_item.service_offering_source_ref).and_return(validater)
    allow(validater).to receive(:process).and_return(validater)
    allow(validater).to receive(:valid).and_return(validity)

    allow(ManageIQ::API::Common::Request).to receive(:current_forwardable).and_return(default_headers)
  end

  context "when the order ID is valid" do
    let(:params) { order.id.to_s }
    let(:order_response) { TopologicalInventoryApiClient::InlineResponse200.new(:task_id => "100") }

    context "when the source is valid" do
      before do
        request_stubs = {
          :body => {
            :service_parameters          => service_parameters,
            :provider_control_parameters => provider_control_parameters,
            :service_plan_id             => service_plan_ref,
          }.to_json,
          :headers => default_headers
        }
        stub_request(:post, "http://localhost/api/topological-inventory/v1.0/service_offerings/998/order")
          .with(request_stubs)
          .to_return(:status => 200, :body => order_response.to_json, :headers => {"Content-type" => "application/json"})
      end

      it "updates the order item with the task id" do
        expect(submit_order.process.order.order_items.first.topology_task_ref).to eq("100")
      end
    end

    context "when the source is not valid" do
      let(:validity) { false }

      it "throws an unauthorized exception" do
        ManageIQ::API::Common::Request.with_request(default_request) do
          expect { submit_order.process }.to raise_error(Catalog::NotAuthorized)
        end
      end
    end
  end

  context "when the order ID is invalid" do
    let(:params) { 333 }

    it "raises an exception" do
      expect { submit_order.process }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
