describe "PortfolioItemRequests", :type => :request do
  before { disable_tenancy }

  let(:service_offering_ref) { "998" }
  let(:service_offering_source_ref) { "568" }
  let(:order)                { create(:order) }
  let(:icon_id) { 1 }
  let(:portfolio_item)       do
    create(:portfolio_item, :service_offering_ref        => service_offering_ref,
                            :service_offering_source_ref => service_offering_source_ref,
                            :service_offering_icon_id => icon_id )
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

      it 'deletes the record' do
        expect(response).to have_http_status(204)
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

  context "icons" do
    let(:api_instance) { double }
    let(:topological_inventory) do
      class_double("TopologicalInventory")
        .as_stubbed_const(:transfer_nested_constants => true)
    end

    let(:topology_service_offering_icon) do
      TopologicalInventoryApiClient::ServiceOfferingIcon.new(
        :id => icon_id,
        :source_ref => "src",
        :data => "img")
    end
    let(:portfolio_item_without_overriden_icon) do
      create(:portfolio_item,
             :service_offering_icon_id => topology_service_offering_icon.id)
    end

    before do
      allow(topological_inventory).to receive(:call).and_yield(api_instance)
    end
    context "when we have to hit topology for the icon data" do
      it "reaches out to topology to get the icon" do
        expect(api_instance).to receive(:show_service_offering_icon).with(topology_service_offering_icon.id.to_s).and_return(topology_service_offering_icon)

        get "#{api}/portfolio_items/#{portfolio_item_without_overriden_icon.id}/icon", :headers => admin_headers

        expect(response).to have_http_status(200)
        expect(json["id"]).to eq topology_service_offering_icon.id
      end
    end
  end
end
