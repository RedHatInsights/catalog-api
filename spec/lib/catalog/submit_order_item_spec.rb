describe Catalog::SubmitOrderItem, :type => [:service, :topology, :current_forwardable] do
  let(:service_offering_ref) { "998" }
  let(:service_plan_ref) { "991" }
  let(:order) { create(:order) }
  let(:service_parameters) { {'var1' => 'Fred', 'var2' => 'Wilma'} }
  let(:provider_control_parameters) { {'namespace' => 'Bedrock'} }
  let(:portfolio_item) do
    create(:portfolio_item, :service_offering_ref => service_offering_ref, :service_offering_source_ref => "17")
  end
  let!(:service_plan) { create(:service_plan, :portfolio_item => portfolio_item, :base => valid_ddf) }
  let(:submit_order) { described_class.new(params) }
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

  context "when the order ID is valid" do
    let(:params) { order.id.to_s }
    let(:order_response) { TopologicalInventoryApiClient::InlineResponse200.new(:task_id => "100") }

    before do
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
        expect(submit_order.process.order.order_items.first.topology_task_ref).to eq("100")
      end

      it "logs a message" do
        # item.mark_ordered ends up calling a separate rails logger so we need to `allow` here.
        allow(Rails.logger).to receive(:info)

        expect(Rails.logger).to receive(:info).with("OrderItem #{order.order_items.first.id} ordered with topology task ref 100")
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

  context "when the base service_plan has changed from topology" do
    let(:params) { order.id.to_s }
    let(:service_plan_response) do
      topo_service_plan_response.tap do |plan|
        plan.data.first.create_json_schema["schema"]["description"] += " changed service plan"
      end
    end

    it "fails to order" do
      expect { submit_order.process }.to raise_exception(Catalog::InvalidSurvey)
    end
  end

  context "with multiple order items" do
    let(:params) { order.id.to_s }
    let(:order_response) { TopologicalInventoryApiClient::InlineResponse200.new(:task_id => "200") }
    let(:order_items) do
      (1..3).map do |sequence|
        create(:order_item_with_callback,
               :order            => order,
               :service_plan_ref => service_plan_ref,
               :process_sequence => sequence,
               :portfolio_item   => portfolio_item)
      end
    end

    before do
      stub_request(:post, topological_url("service_offerings/998/order"))
        .to_return(:status => 200, :body => order_response.to_json, :headers => {"Content-type" => "application/json"})

      allow(Order).to receive(:find_by!).with(:id => params).and_return(order)
      allow(order).to receive(:order_items).and_return(order_items)
    end

    shared_examples_for "order the desired item" do
      it "orders the desired item" do
        submit_order.process.order.order_items.each.with_index(1) do |item, index|
          if index == ordered_item
            expect(item.state).to eq('Ordered')
          else
            expect(item.state).not_to eq('Ordered')
          end
        end
      end
    end

    context "when no order item is orderable" do
      before do
        order_items.each { |item| allow(item).to receive(:can_order?).and_return(false) }
      end

      it 'does not order any item' do
        submit_order.process.order.order_items.each { |item| expect(item.state).not_to eq('Ordered') }
      end
    end

    context "when the first item becomes orderable" do
      before do
        order_items.each { |item| allow(item).to receive(:can_order?).and_return(true) }
      end

      let(:ordered_item) { 1 }

      it_behaves_like "order the desired item"
    end

    context "when the first item is not orderable the second one is" do
      before do
        allow(order_items.first).to receive(:can_order?).and_return(false)
        allow(order_items.second).to receive(:can_order?).and_return(true)
        allow(order_items.third).to receive(:can_order?).and_return(true)
      end

      let(:ordered_item) { 2 }

      it_behaves_like "order the desired item"
    end

    context "when the first and second items are not orderable but the thrid one is" do
      before do
        allow(order_items.first).to receive(:can_order?).and_return(false)
        allow(order_items.second).to receive(:can_order?).and_return(false)
        allow(order_items.third).to receive(:can_order?).and_return(true)
      end

      let(:ordered_item) { 3 }

      it_behaves_like "order the desired item"
    end
  end
end
