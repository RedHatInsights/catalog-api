describe "PortfolioItemRequests", :type => :request do
  include ServiceSpecHelper

  let(:service_offering_ref) { "998" }
  let(:service_offering_source_ref) { "568" }
  let(:order)                { create(:order) }
  let(:portfolio_item)       do
    create(:portfolio_item, :service_offering_ref        => service_offering_ref,
                            :service_offering_source_ref => service_offering_source_ref)
  end
  let(:portfolio_item_id)    { portfolio_item.id }
  let(:topo_ex)              { ServiceCatalog::TopologyError.new("kaboom") }

  describe 'DELETE admin tagged /portfolio_items/:portfolio_item_id' do
    # TODO: https://github.com/ManageIQ/service_portal-api/issues/85
    let(:valid_attributes) { { :name => 'PatchPortfolio', :description => 'description for patched portfolio' } }

    context 'when :portfolio_item_id is valid' do
      before do
        delete "/api/v0.0/portfolio_items/#{portfolio_item_id}", :headers => admin_headers, :params => valid_attributes
      end

      it 'deletes the record' do
        expect(response).to have_http_status(204)
      end
    end
  end

  context "service plans" do
    let(:svc_object)           { instance_double("ServiceCatalog::ServicePlans") }
    let(:plans)                { [{}, {}] }

    before do
      allow(ServiceCatalog::ServicePlans).to receive(:new).with(portfolio_item.id.to_s).and_return(svc_object)
    end

    it "fetches plans" do
      allow(svc_object).to receive(:process).and_return(svc_object)
      allow(svc_object).to receive(:items).and_return(plans)

      get "/api/v0.0/portfolio_items/#{portfolio_item.id}/service_plans"

      expect(JSON.parse(response.body).count).to eq(2)
      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
    end

    it "raises error" do
      allow(svc_object).to receive(:process).and_raise(topo_ex)

      get "/api/v0.0/portfolio_items/#{portfolio_item.id}/service_plans"
      expect(response).to have_http_status(:internal_server_error)
    end
  end

  context "provider control parameters" do
    let(:svc_object)  { instance_double("ServiceCatalog::ProviderControlParameters") }
    let(:url)         { "/api/v0.0/portfolio_items/#{portfolio_item.id}/provider_control_parameters" }

    before do
      allow(ServiceCatalog::ProviderControlParameters).to receive(:new).with(portfolio_item.id.to_s).and_return(svc_object)
    end

    it "fetches plans" do
      allow(svc_object).to receive(:process).and_return(svc_object)
      allow(svc_object).to receive(:data).and_return(:fred => 'bedrock')

      get url

      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
    end

    it "raises error" do
      allow(svc_object).to receive(:process).and_raise(topo_ex)

      get url

      expect(response).to have_http_status(:internal_server_error)
    end
  end
end
