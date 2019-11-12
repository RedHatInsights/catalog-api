describe Catalog::CreateRequestForAppliedInventories, :type => :service do
  let(:subject) { described_class.new(order_item.order.id) }
  let!(:order_item) { create(:order_item, :portfolio_item => portfolio_item, :service_parameters => "service_parameters") }
  let(:portfolio_item) { create(:portfolio_item, :service_offering_ref => 123) }

  around do |example|
    with_modified_env(:TOPOLOGICAL_INVENTORY_URL => "http://localhost") do
      example.call
    end
  end

  before do
    allow(ManageIQ::API::Common::Request).to receive(:current_forwardable).and_return(default_headers)
  end

  describe "#process" do
    let(:topology_response) { TopologicalInventoryApiClient::InlineResponse200.new(:task_id => "321") }
    let(:request_body) do
      TopologicalInventoryApiClient::AppliedInventoriesParametersServicePlan.new(
        :service_parameters => order_item.service_parameters
      ).to_json
    end

    before do
      stub_request(:post, "http://localhost/api/topological-inventory/v1.0/service_offerings/123/applied_inventories")
        .with(:body => request_body)
        .to_return(:status => 200, :body => topology_response.to_json, :headers => default_headers)
    end

    it "makes a request to compute the applied inventories" do
      subject.process
      expect(a_request(:post, "http://localhost/api/topological-inventory/v1.0/service_offerings/123/applied_inventories")
        .with(:body => request_body)).to have_been_made
    end

    it "updates the order item topology task ref" do
      expect(order_item.topology_task_ref).to eq(nil)
      subject.process
      order_item.reload
      expect(order_item.topology_task_ref).to eq("321")
    end

    it "updates the order state" do
      expect(subject.process.order.state).to eq("Waiting for inventories")
    end
  end
end
