describe Catalog::SubmitOrderItem, :type => [:service, :topology, :current_forwardable] do
  let(:service_offering_ref) { "998" }
  let(:service_plan_ref) { "991" }
  let(:order) { create(:order) }
  let(:service_parameters) { {'username' => 'Fred', 'quest' => 'Test Catalog'} }
  let(:provider_control_parameters) { {'namespace' => 'Bedrock'} }
  let(:portfolio_item) do
    create(:portfolio_item, :service_plans => [service_plan], :service_offering_ref => service_offering_ref, :service_offering_source_ref => "17")
  end
  let(:service_plan) { create(:service_plan, :base => valid_ddf, :modified => nil) }
  let(:submit_order) { described_class.new(order_item) }
  let(:validater) { instance_double(Api::V1x0::Catalog::ValidateSource) }
  let(:validity) { true }
  let(:valid_ddf) { JSON.parse(File.read(Rails.root.join("spec", "support", "ddf", "valid_service_plan_ddf.json"))) }

  let(:topo_service_plan) do
    TopologicalInventoryApiClient::ServicePlan.new(
      :name               => "The Plan",
      :id                 => "1",
      :description        => "A Service Plan",
      :create_json_schema => valid_ddf
    )
  end

  let(:topo_service_plan_response) { TopologicalInventoryApiClient::ServicePlansCollection.new(:data => [topo_service_plan]) }
  let(:service_plan_response) { topo_service_plan_response }

  include_context "uses an order item with raw service parameters set"

  before do
    allow(Api::V1x0::Catalog::ValidateSource).to receive(:new).with(portfolio_item.service_offering_source_ref).and_return(validater)
    allow(validater).to receive(:process).and_return(validater)
    allow(validater).to receive(:valid).and_return(validity)

    stub_request(:get, topological_url("service_offerings/#{service_offering_ref}/service_plans"))
      .to_return(:status => 200, :body => service_plan_response.to_json, :headers => default_headers)
  end

  context "when the order item is valid" do
    let(:order_response) { TopologicalInventoryApiClient::InlineResponse200.new(:task_id => "100") }
    let(:workspace_builder) { instance_double(Catalog::WorkspaceBuilder, :process => double(:workspace => {})) }

    before do
      allow(Catalog::WorkspaceBuilder).to receive(:new).with(order_item.order).and_return(workspace_builder)

      stub_request(:post, topological_url("service_offerings/998/order"))
        .with(
          :body    => {
            :service_parameters          => service_parameters,
            :provider_control_parameters => provider_control_parameters,
            :service_plan_id             => service_plan_ref,
          }.to_json,
          :headers => default_headers
        )
        .to_return(:status => 200, :body => order_response.to_json, :headers => {"Content-type" => "application/json"})
    end

    context "when the source is valid" do
      it "updates the order item with the task id" do
        expect(submit_order.process.order_item.topology_task_ref).to eq("100")
      end

      it "logs a message" do
        # item.mark_ordered ends up calling a separate rails logger so we need to `allow` here.
        allow(Rails.logger).to receive(:info)

        expect(Rails.logger).to receive(:info).with("OrderItem #{order_item.id} ordered with topology task ref 100")
        submit_order.process
      end
    end

    context "when sending extra parameters" do
      before do
        order_item.update!(:service_parameters => service_parameters.merge(:extra_param => "extra! extra!"))
      end

      it "only sends the parameters specified in the schema" do
        submit_order.process
        expect(a_request(:post, topological_url("service_offerings/998/order")).with { |req| req.body.exclude?("extra_param") }).to have_been_made
      end
    end

    context "when the source is not valid" do
      let(:validity) { false }

      it "throws an unauthorized exception" do
        Insights::API::Common::Request.with_request(default_request) do
          submit_order.process
          msg = order_item.progress_messages.last
          expect(msg.level).to eq "error"
          expect(msg.message).to eq "Error Submitting Order Item: Catalog::NotAuthorized"
        end
      end
    end
  end

  context "when the base service_plan has changed from topology" do
    let(:service_plan_response) do
      topo_service_plan_response.tap do |plan|
        plan.data.first.create_json_schema["schema"]["description"] += " changed service plan"
      end
    end

    it "fails to order" do
      submit_order.process
      msg = order_item.progress_messages.last
      expect(msg.level).to eq "error"
      expect(msg.message).to match(/Error Submitting Order Item: The underlying survey/)
    end
  end
end
