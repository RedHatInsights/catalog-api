describe "PortfolioItemRequests", :type => :request do
  before { disable_tenancy }

  let(:service_offering_ref) { "998" }
  let(:service_offering_source_ref) { "568" }
  let(:order)                { create(:order) }
  let(:portfolio_item)       do
    create(:portfolio_item, :service_offering_ref        => service_offering_ref,
                            :service_offering_source_ref => service_offering_source_ref)
  end
  let(:portfolio_item_id)    { portfolio_item.id }
  let(:topo_ex)              { ServiceCatalog::TopologyError.new("kaboom") }

  %w(admin user).each do |tag|
    describe "GET #{tag} /portfolio_items/:portfolio_item_id" do
      before do
        get "#{api}/portfolio_items/#{portfolio_item_id}", :headers => admin_headers
      end

      context 'the portfolio_item exists' do
        it 'returns status code 200' do
          expect(response).to have_http_status(200)
        end

        it 'returns the portfolio_item we asked for' do
          expect(json["id"]).to eq portfolio_item.id
        end
      end
    end
  end

  describe 'DELETE admin tagged /portfolio_items/:portfolio_item_id' do
    # TODO: https://github.com/ManageIQ/service_portal-api/issues/85
    let(:valid_attributes) { { :name => 'PatchPortfolio', :description => 'description for patched portfolio' } }

    context 'when :portfolio_item_id is valid' do
      before do
        delete "/api/v0.0/portfolio_items/#{portfolio_item_id}", :headers => admin_headers, :params => valid_attributes
      end

      it 'discards the record' do
        expect(response).to have_http_status(204)
      end

      it 'marks the icon as discarded instead of deleting it from the db' do
        expect(PortfolioItem.find_by(:id => portfolio_item_id).discarded_at).to_not be_nil
      end
    end
  end

  describe 'GET portfolio items' do
    context "v0.0" do
      it "success" do
        portfolio_item
        get "/api/v0.0/portfolio_items"
        expect(response).to have_http_status(200)
        expect(JSON.parse(response.body).count).to eq(1)
      end
    end

    context "v0.1" do
      it "success" do
        portfolio_item
        get "/api/v0.1/portfolio_items"
        expect(response).to have_http_status(200)
        expect(JSON.parse(response.body)['data'].count).to eq(1)
      end
    end
  end

  context "when adding portfolio items" do
    let(:add_to_portfolio_svc) { double(ServiceOffering::AddToPortfolioItem) }
    let(:params) { { :service_offering_ref => service_offering_ref } }

    before do
      allow(ServiceOffering::AddToPortfolioItem).to receive(:new).and_return(add_to_portfolio_svc)
    end

    it "returns not found when topology doesn't have the service_offering_ref" do
      allow(add_to_portfolio_svc).to receive(:process).and_raise(topo_ex)

      post "#{api}/portfolio_items", :params => params
      expect(response).to have_http_status(:not_found)
    end

    it "returns the new portfolio item when topology has the service_offering_ref" do
      allow(add_to_portfolio_svc).to receive(:process).and_return(add_to_portfolio_svc)
      allow(add_to_portfolio_svc).to receive(:item).and_return(portfolio_item)

      post "#{api}/portfolio_items", :params => params
      expect(response).to have_http_status(:ok)
      expect(json["id"]).to eq portfolio_item.id
      expect(json["service_offering_ref"]).to eq service_offering_ref
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
