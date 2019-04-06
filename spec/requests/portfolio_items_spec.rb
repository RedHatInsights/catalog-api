describe "PortfolioItemRequests", :type => :request do
  around do |example|
    bypass_rbac do
      example.call
    end
  end

  let(:service_offering_ref) { "998" }
  let(:service_offering_source_ref) { "568" }
  let(:tenant) { create(:tenant, :external_tenant => default_user_hash['identity']['account_number']) }
  let(:order) { create(:order, :tenant_id => tenant.id) }
  let(:icon_id) { 1 }
  let(:portfolio_item) do
    create(:portfolio_item, :service_offering_ref        => service_offering_ref,
                            :service_offering_source_ref => service_offering_source_ref,
                            :service_offering_icon_ref   => icon_id,
                            :tenant_id                   => tenant.id)
  end
  let(:portfolio_item_id)    { portfolio_item.id }
  let(:topo_ex)              { Catalog::TopologyError.new("kaboom") }

  describe "GET /portfolio_items/:portfolio_item_id" do
    before do
      get "#{api}/portfolio_items/#{portfolio_item_id}", :headers => default_headers
    end

    context 'the portfolio_item exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns the portfolio_item we asked for' do
        expect(json["id"]).to eq portfolio_item.id.to_s
      end
    end
  end

  describe "GET v1.0 /portfolio_items/:portfolio_item_id" do
    before do
      get "#{api}/portfolio_items/#{portfolio_item_id}", :headers => default_headers
    end

    context 'the portfolio_item exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns the portfolio_item we asked for' do
        expect(json["id"]).to eq portfolio_item.id.to_s
      end
    end
  end

  describe 'DELETE admin tagged /portfolio_items/:portfolio_item_id' do
    # TODO: https://github.com/ManageIQ/catalog-api/issues/85
    let(:valid_attributes) { { :name => 'PatchPortfolio', :description => 'description for patched portfolio' } }

    context 'when v1.0 :portfolio_item_id is valid' do
      before do
        delete "#{api}/portfolio_items/#{portfolio_item_id}", :headers => default_headers, :params => valid_attributes
      end

      it 'discards the record' do
        expect(response).to have_http_status(204)
      end

      it 'is still present in the db, just with deleted_at set' do
        expect(PortfolioItem.with_discarded.find_by(:id => portfolio_item_id).discarded_at).to_not be_nil
      end

      it "can't be requested" do
        expect { get("/#{api}/portfolio_items/#{portfolio_item_id}", :headers => default_headers) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'GET portfolio items' do
    context "v1.0" do
      it "success" do
        portfolio_item
        get "/#{api}/portfolio_items", :headers => default_headers
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

      post "#{api}/portfolio_items", :params => params, :headers => default_headers
      expect(response).to have_http_status(:not_found)
    end

    it "returns the new portfolio item when topology has the service_offering_ref" do
      allow(add_to_portfolio_svc).to receive(:process).and_return(add_to_portfolio_svc)
      allow(add_to_portfolio_svc).to receive(:item).and_return(portfolio_item)

      post "#{api}/portfolio_items", :params => params, :headers => default_headers
      expect(response).to have_http_status(:ok)
      expect(json["id"]).to eq portfolio_item.id.to_s
      expect(json["service_offering_ref"]).to eq service_offering_ref
    end
  end

  context "service plans" do
    let(:svc_object)           { instance_double("Catalog::ServicePlans") }
    let(:plans)                { [{}, {}] }

    before do
      allow(Catalog::ServicePlans).to receive(:new).with(portfolio_item.id.to_s).and_return(svc_object)
    end

    it "fetches plans" do
      allow(svc_object).to receive(:process).and_return(svc_object)
      allow(svc_object).to receive(:items).and_return(plans)

      get "/#{api}/portfolio_items/#{portfolio_item.id}/service_plans", :headers => default_headers

      expect(JSON.parse(response.body).count).to eq(2)
      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
    end

    it "raises error" do
      allow(svc_object).to receive(:process).and_raise(topo_ex)

      get "/#{api}/portfolio_items/#{portfolio_item.id}/service_plans", :headers => default_headers
      expect(response).to have_http_status(:internal_server_error)
    end
  end

  context "v1.0 provider control parameters" do
    let(:svc_object)  { instance_double("Catalog::ProviderControlParameters") }
    let(:url)         { "#{api}/portfolio_items/#{portfolio_item.id}/provider_control_parameters" }

    before do
      allow(Catalog::ProviderControlParameters).to receive(:new).with(portfolio_item.id.to_s).and_return(svc_object)
    end

    it "fetches plans" do
      allow(svc_object).to receive(:process).and_return(svc_object)
      allow(svc_object).to receive(:data).and_return(:fred => 'bedrock')

      get url, :headers => default_headers

      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
    end

    it "raises error" do
      allow(svc_object).to receive(:process).and_raise(topo_ex)

      get url, :headers => default_headers

      expect(response).to have_http_status(:internal_server_error)
    end
  end

  describe "patching portfolio items" do
    let(:valid_attributes) { { :name => 'PatchPortfolio', :description => 'PatchDescription', :workflow_ref => 'PatchWorkflowRef'} }
    let(:invalid_attributes) { { :name => 'PatchPortfolio', :service_offering_ref => "27" } }

    context "when passing in valid attributes" do
      before do
        patch "#{api}/portfolio_items/#{portfolio_item.id}", :params => valid_attributes, :headers => default_headers
      end

      it 'returns a 200' do
        expect(response).to have_http_status(:ok)
      end

      it 'patches the record' do
        expect(json).to include(valid_attributes.stringify_keys)
      end
    end

    context "when passing in read-only attributes" do
      before do
        patch "#{api}/portfolio_items/#{portfolio_item.id}", :params => invalid_attributes, :headers => default_headers
      end

      it 'returns a 200' do
        expect(response).to have_http_status(:ok)
      end

      it 'updates the field that is allowed' do
        expect(json["name"]).to eq invalid_attributes[:name]
      end

      it "does not update the read-only field" do
        expect(json["service_offering_ref"]).to_not eq invalid_attributes[:service_offering_ref]
      end
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
        :id         => icon_id.to_s,
        :source_ref => "src",
        :data       => "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 100 100\"><defs><style>.cls-1{fill:#d71e00}.cls-2{fill:#c21a00}.cls-3{fill:#fff}.cls-4{fill:#eaeaea}</style></defs><title>Logo</title><g id=\"Layer_1\" data-name=\"Layer 1\"><circle class=\"cls-1\" cx=\"50\" cy=\"50\" r=\"50\" transform=\"rotate(-45 50 50)\"/><path class=\"cls-2\" d=\"M85.36 14.64a50 50 0 0 1-70.72 70.72z\"/><path d=\"M31 31.36a1.94 1.94 0 0 1-3.62-.89.43.43 0 0 1 .53-.44 3.32 3.32 0 0 0 2.81.7.43.43 0 0 1 .28.63z\"/><path class=\"cls-3\" d=\"M77.63 44.76C77.12 41.34 73 21 66.32 21c-2.44 0-4.59 3.35-6 6.88-.44 1.06-1.23 1.08-1.63 0-1.45-3.72-2.81-6.88-5.41-6.88-9.94 0-5.44 24.18-14.28 24.18-4.57 0-5.37-10.59-5.5-14.72 2.19.65 3.3-1 3.55-2.61a.63.63 0 0 0-.48-.72 3.36 3.36 0 0 0-3 .89h-6.26a1 1 0 0 0-.68.28l-.53.53h-3.89a.54.54 0 0 0-.38.16l-3.95 3.95a.54.54 0 0 0 .38.91h11.45c.6 6.26 1.75 22 16.42 17.19l-.32 5-1.44 22.42a1 1 0 0 0 1 1h4.9a1 1 0 0 0 1-1l-.61-23.33-.15-5.81c6-2.78 9-5.66 16.19-6.75-1.59 2.62-2.05 6.87-2.06 8-.06 6 2.55 8.74 5 13.22L63.73 78a1 1 0 0 0 .89 1.32h4.64a1 1 0 0 0 .93-.74L74 62.6c-4.83-7.43 1.83-15.31 3.41-17a1 1 0 0 0 .22-.84zM31 31.36a1.94 1.94 0 0 1-3.62-.89.43.43 0 0 1 .53-.44 3.32 3.32 0 0 0 2.81.7.43.43 0 0 1 .28.63z\"/><path class=\"cls-4\" d=\"M46.13 51.07c-14.67 4.85-15.82-10.93-16.42-17.19H18.65l2.1 2.12a1 1 0 0 0 .68.28h6c0 5.8 1.13 20.2 14 20.2a31.34 31.34 0 0 0 4.42-.35zM50.41 49.36l.15 5.81a108.2 108.2 0 0 0 14-4.54 19.79 19.79 0 0 1 2.06-8c-7.16 1.07-10.18 3.95-16.21 6.73z\"/></g></svg>"
      )
    end
    let(:portfolio_item_without_overriden_icon) do
      create(:portfolio_item,
             :service_offering_icon_ref => topology_service_offering_icon.id, :tenant_id => tenant.id)
    end

    before do
      allow(topological_inventory).to receive(:call).and_yield(api_instance)
    end
    context "when we have to hit topology for the icon data" do
      it "reaches out to topology to get the icon" do
        expect(api_instance).to receive(:show_service_offering_icon).with(topology_service_offering_icon.id.to_s).and_return(topology_service_offering_icon)

        get "#{api}/portfolio_items/#{portfolio_item_without_overriden_icon.id}/icon", :headers => default_headers

        expect(response).to have_http_status(200)
        expect(response.content_type).to eq "image/svg+xml"
      end
    end
  end
end
