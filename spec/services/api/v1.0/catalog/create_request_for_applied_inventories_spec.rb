describe Api::V1x0::Catalog::CreateRequestForAppliedInventories, :type => :service do
  let(:subject) { described_class.new(order_item.order) }
  let(:service_plan_ref) { "991" }
  let(:req) { {:headers => default_headers, :original_url => "localhost/nope"} }
  let!(:order_item) do
    Insights::API::Common::Request.with_request(req) do
      create(:order_item, :portfolio_item => portfolio_item, :service_parameters => "service_parameters", :service_plan_ref => service_plan_ref)
    end
  end
  let(:portfolio_item) { create(:portfolio_item, :service_offering_ref => 123) }

  around do |example|
    with_modified_env(:CATALOG_INVENTORY_URL => "http://inventory.example.com") do
      example.call
    end
  end

  let(:topology_response) { CatalogInventoryApiClient::InlineResponse200.new(:task_id => "321") }
  let(:request_body) do
    CatalogInventoryApiClient::AppliedInventoriesParametersServicePlan.new(
      :service_parameters => order_item.service_parameters
    ).to_json
  end

  before do
    allow(Insights::API::Common::Request).to receive(:current_forwardable).and_return(default_headers)
    stub_request(:post, catalog_inventory_url("service_offerings/123/applied_inventories"))
      .with(:body => request_body)
      .to_return(:status => 200, :body => topology_response.to_json, :headers => default_headers)
  end

  describe "#process" do
    context "when there is not a modified survey" do
      it "makes a request to compute the applied inventories" do
        subject.process
        expect(a_request(:post, catalog_inventory_url("service_offerings/123/applied_inventories"))
          .with(:body => request_body)).to have_been_made
      end

      it "updates the order item inventory task ref" do
        expect(order_item.topology_task_ref).to eq(nil)
        subject.process
        order_item.reload
        expect(order_item.topology_task_ref).to eq("321")
      end

      it "logs a message about the order item receiving a new task id" do
        expect(Rails.logger).to receive(:info).with("OrderItem #{order_item.id} updated with inventory task ref 321")
        subject.process
      end

      it "creates a progress message on the order item" do
        subject.process
        progress_message = ProgressMessage.last
        expect(progress_message.level).to eq("info")
        expect(progress_message.message).to eq("Computing inventories")
        expect(progress_message.messageable_id).to eq(order_item.order.id)
        expect(progress_message.messageable_type).to eq(order_item.order.class.name)
      end
    end

    context "when there is a modified survey" do
      let!(:service_plan) { create(:service_plan, :portfolio_item => portfolio_item) }

      before do
        allow(Catalog::SurveyCompare).to receive(:collect_changed).with(portfolio_item.service_plans).and_return([service_plan])
        allow(service_plan).to receive(:invalid_survey_message).and_return("Invalid survey")
      end

      context "when the survey does not match inventory" do
        it "raises an error" do
          expect { subject.process }.to raise_exception do |error|
            expect(error).to be_a(Catalog::InvalidSurvey)
            expect(JSON.parse(error.message)).to eq(["Invalid survey"])
          end
        end
      end
    end
  end
end
