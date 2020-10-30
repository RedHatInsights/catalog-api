describe "v1.2 - OrdersCotnroller", :type => [:request, :controller, :v1x2] do
  let!(:order) { create(:order) }
  let!(:order_item) { create(:order_item, :order => order) }
  let!(:order2) { create(:order) }
  let!(:order_item2) { create(:order_item, :order => order2) }
  let(:catalog_access) { instance_double(Insights::API::Common::RBAC::Access, :scopes => %w[admin]) }
  before do
    allow(Insights::API::Common::RBAC::Access).to receive(:new).and_return(catalog_access)
    allow(catalog_access).to receive(:process).and_return(catalog_access)
  end

  describe "#submit_order" do
    let(:service_offering_service) { instance_double("Api::V1x0::Catalog::ServiceOffering") }
    subject { post "#{api_version}/orders/#{order.id}/submit_order", :headers => default_headers }

    before do
      allow(Api::V1x0::Catalog::ServiceOffering).to receive(:new).with(order).and_return(service_offering_service)
      allow(service_offering_service).to receive(:process).and_return(service_offering_service)
      allow(service_offering_service).to receive(:archived).and_return(archived)
      allow(service_offering_service).to receive(:order).and_return(order)
    end

    context "when the service offering has not been archived" do
      let(:archived) { false }
      let(:svc_object) { instance_double("Catalog::CreateRequestForAppliedInventories") }

      before do |example|
        allow(Api::V1x0::Catalog::CreateRequestForAppliedInventories).to receive(:new).with(order).and_return(svc_object)
        allow(svc_object).to receive(:process).and_return(svc_object)
        allow(svc_object).to receive(:order).and_return(order)
        subject unless example.metadata[:subject_inside]
      end

      it_behaves_like "action that tests authorization", :submit_order?, Order

      it "creates a request for applied inventories", :subject_inside do
        expect(svc_object).to receive(:process)
        subject
      end

      it "returns a 200" do
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
      end

      it "returns the order in json format" do
        parsed_body = JSON.parse(response.body)
        expect(parsed_body["state"]).to eq("Created")
        expect(parsed_body["id"]).to eq(order.id.to_s)
      end
    end

    context "when the service offering has been archived" do
      let(:archived) { true }

      before do |example|
        subject unless example.metadata[:subject_inside]
      end

      it_behaves_like "action that tests authorization", :submit_order?, Order

      it "logs the error", :subject_inside do
        expect(Rails.logger).to receive(:error).with(/Service offering for order #{order.id} has been archived/).twice

        subject
      end

      it "creates progress messages for the order items" do
        expect(ProgressMessage.last.message).to match(/has been archived/)
      end

      it "marks the order as failed" do
        order.reload
        expect(order.state).to eq("Failed")
      end

      it "returns a 400" do
        expect(response).to have_http_status(:bad_request)
      end
    end

    context "when the survey has changed" do
      let(:archived) { false }

      let!(:order_item) { create(:order_item, :order => order) }
      let!(:service_plan) { create(:service_plan, :portfolio_item => order.order_items.first.portfolio_item) }

      before do |example|
        allow(::Catalog::SurveyCompare).to receive(:any_changed?).with(order.order_items.first.portfolio_item.service_plans).and_return(true)

        subject unless example.metadata[:subject_inside]
      end

      it_behaves_like "action that tests authorization", :submit_order?, Order

      it "returns a 400" do
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(400)
        expect(first_error_detail).to match(/Catalog::InvalidSurvey/)

        order.reload
        expect(order.state).to eq("Failed")
      end
    end

    describe "when exceptions are raised" do
      let(:archived) { false }
      shared_examples_for "with errors" do
        it "returns Failed state" do
          subject
          order.reload
          expect(order.state).to eq("Failed")
        end
      end

      context "from service_offering_service" do
        before { allow(service_offering_service).to receive(:process).and_raise(StandardError) }

        it_behaves_like "with errors"
      end

      context "from topo service" do
        before { allow(TopologicalInventory::Service).to receive(:call).and_raise(Catalog::TopologyError.new("boom")) }

        it_behaves_like "with errors"
      end
    end
  end
end
