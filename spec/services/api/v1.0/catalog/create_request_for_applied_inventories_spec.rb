describe Api::V1x0::Catalog::CreateRequestForAppliedInventories, :type => :service do
  let(:subject) { described_class.new(order_item.order) }
  let(:service_plan_ref) { "991" }
  let(:req) { {:headers => default_headers, :original_url => "localhost/nope"} }
  let(:order) { create(:order) }
  let!(:order_item) do
    Insights::API::Common::Request.with_request(req) do
      create(:order_item, :portfolio_item => portfolio_item, :order => order, :service_parameters => "service_parameters", :service_plan_ref => service_plan_ref)
    end
  end
  let(:portfolio_item) { create(:portfolio_item, :service_offering_ref => 123) }

  around do |example|
    with_modified_env(:CATALOG_INVENTORY_URL => "http://inventory.example.com") do
      example.call
    end
  end

  let(:create_approval_request) { instance_double(Catalog::CreateApprovalRequest) }
  let(:evaluate_order_process) { instance_double(Catalog::EvaluateOrderProcess) }
  let(:tag_resources_instance) { instance_double(Tags::CollectTagResources) }
  let(:tag_resources) { [] }

  before do
    allow(Insights::API::Common::Request).to receive(:current_forwardable).and_return(default_headers)
    allow(Catalog::CreateApprovalRequest).to receive(:new).with(nil, tag_resources, order_item).and_return(create_approval_request)
    allow(create_approval_request).to receive(:process)
    allow(Catalog::EvaluateOrderProcess).to receive(:new).with(nil, order, tag_resources).and_return(evaluate_order_process)
    allow(evaluate_order_process).to receive(:process)
    allow(Tags::CollectTagResources).to receive(:new).and_return(tag_resources_instance)
    allow(tag_resources_instance).to receive(:process).and_return(tag_resources_instance)
    allow(tag_resources_instance).to receive(:tag_resources).and_return(tag_resources)
  end

  describe "#process" do
    context "when there is not a modified survey" do
      it "logs a message about the order item receiving a new task id" do
        expect(Rails.logger).to receive(:info).with("Evaluating order processes for order item id #{order_item.id}").ordered
        expect(Rails.logger).to receive(:info).with("Creating approval request for order_item id #{order_item.id}").ordered
        subject.process
      end

      it "creates a progress message on the order item" do
        subject.process
        progress_message = ProgressMessage.last
        expect(progress_message.level).to eq("info")
        expect(progress_message.message).to eq("Computed Tags")
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
