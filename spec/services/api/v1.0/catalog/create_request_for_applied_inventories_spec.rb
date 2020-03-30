describe Catalog::CreateRequestForAppliedInventories, :type => :service do
  let(:subject) { described_class.new(order_item.order) }
  let(:service_plan_ref) { "991" }
  let!(:order_item) { create(:order_item, :portfolio_item => portfolio_item, :service_parameters => "service_parameters", :service_plan_ref => service_plan_ref) }
  let(:portfolio_item) { create(:portfolio_item, :service_offering_ref => 123) }

  around do |example|
    with_modified_env(:TOPOLOGICAL_INVENTORY_URL => "http://topology.example.com") do
      example.call
    end
  end

  let(:topology_response) { TopologicalInventoryApiClient::InlineResponse200.new(:task_id => "321") }
  let(:request_body) do
    TopologicalInventoryApiClient::AppliedInventoriesParametersServicePlan.new(
      :service_parameters => order_item.service_parameters
    ).to_json
  end

  before do
    allow(Insights::API::Common::Request).to receive(:current_forwardable).and_return(default_headers)
    stub_request(:post, topological_url("service_offerings/123/applied_inventories"))
      .with(:body => request_body)
      .to_return(:status => 200, :body => topology_response.to_json, :headers => default_headers)
  end

  describe "#process" do
    context "when there is not a modified survey" do
      it "makes a request to compute the applied inventories" do
        subject.process
        expect(a_request(:post, topological_url("service_offerings/123/applied_inventories"))
          .with(:body => request_body)).to have_been_made
      end

      it "updates the order item topology task ref" do
        expect(order_item.topology_task_ref).to eq(nil)
        subject.process
        order_item.reload
        expect(order_item.topology_task_ref).to eq("321")
      end

      it "creates a progress message on the order item" do
        subject.process
        progress_message = ProgressMessage.last
        expect(progress_message.level).to eq("info")
        expect(progress_message.message).to eq("Waiting for inventories")
        expect(progress_message.order_item_id).to eq(order_item.id.to_s)
      end
    end

    context "when there is a modified survey" do
      let!(:service_plan) { create(:service_plan, :portfolio_item => portfolio_item) }
      before { allow(Catalog::SurveyCompare).to receive(:any_changed?).with(portfolio_item.service_plans).and_return(true) }

      context "when the survey does not match topology" do
        it "raises an error" do
          expect { subject.process }.to raise_exception(Catalog::InvalidSurvey)
        end
      end
    end
  end
end
