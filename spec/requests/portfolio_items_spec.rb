describe "PortfolioItemRequests", :type => :request do
  around do |example|
    bypass_rbac do
      example.call
    end
  end

  let(:service_offering_ref) { "998" }
  let(:service_offering_source_ref) { "568" }
  let(:tenant) { create(:tenant) }
  let(:order) { create(:order, :tenant_id => tenant.id) }
  let!(:portfolio) { create(:portfolio, :tenant_id => tenant.id) }
  let!(:portfolio_items) { portfolio.portfolio_items << portfolio_item }
  let(:portfolio_id) { portfolio.id }
  let(:portfolio_item) do
    create(:portfolio_item, :service_offering_ref        => service_offering_ref,
                            :service_offering_source_ref => service_offering_source_ref,
                            :portfolio_id                => portfolio.id,
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

    context 'the portfolio_item does not exist' do
      let(:portfolio_item_id) { 0 }

      it "can't be requested" do
        expect(response).to have_http_status(404)
      end
    end
  end

  describe "GET /portfolios/:portfolio_id/portfolio_items" do
    before do
      get "#{api}/portfolios/#{portfolio_id}/portfolio_items", :headers => default_headers
    end

    context "when the portfolio exists" do
      it 'returns all associated portfolio_items' do
        expect(json).not_to be_empty
        expect(json['meta']['count']).to eq 1
        portfolio_item_ids = portfolio_items.map { |x| x.id.to_s }.sort
        expect(json['data'].map { |x| x['id'] }.sort).to eq portfolio_item_ids
      end
    end

    context "when the portfolio does not exist" do
      let(:portfolio_id) { portfolio.id + 100 }

      it 'returns a 404' do
        expect(json["message"]).to eq("Not Found")
        expect(response.status).to eq(404)
      end
    end
  end

  describe "POST /portfolios/:portfolio_id/portfolio_items" do
    let(:params) { {:portfolio_item_id => portfolio_item.id} }
    before do
      post "#{api}/portfolios/#{portfolio.id}/portfolio_items", :params => params, :headers => default_headers
    end

    it 'returns a 200' do
      expect(response).to have_http_status(200)
    end

    it 'returns the portfolio_item which now points back to the portfolio' do
      expect(json.size).to eq 1
      expect(json.first['portfolio_id']).to eq portfolio.id.to_s
    end
  end

  describe 'DELETE admin tagged /portfolio_items/:portfolio_item_id' do
    context 'when v1.0 :portfolio_item_id is valid' do
      before do
        delete "#{api}/portfolio_items/#{portfolio_item_id}", :headers => default_headers
      end

      it 'discards the record' do
        expect(response).to have_http_status(:ok)
      end

      it 'is still present in the db, just with deleted_at set' do
        expect(PortfolioItem.with_discarded.find_by(:id => portfolio_item_id).discarded_at).to_not be_nil
      end

      it 'returns the restore_key in the body' do
        expect(json["restore_key"]).to eq Digest::SHA1.hexdigest(PortfolioItem.with_discarded.find(portfolio_item_id).discarded_at.to_s)
      end
    end
  end

  describe 'POST /portfolio_items/{portfolio_item_id}/undelete' do
    let(:undelete) { post "#{api}/portfolio_items/#{portfolio_item_id}/undelete", :params => { :restore_key => restore_key }, :headers => default_headers }
    let(:restore_key) { Digest::SHA1.hexdigest(portfolio_item.discarded_at.to_s) }

    context "when restoring a portfolio_item that has been discarded" do
      before do
        portfolio_item.discard
        undelete
      end

      it "returns a 200" do
        expect(response).to have_http_status :ok
      end

      it "returns the undeleted portfolio_item" do
        expect(json["id"]).to eq portfolio_item_id.to_s
        expect(json["name"]).to eq portfolio_item.name
      end
    end

    context 'when attempting to restore with the wrong restore_key' do
      let(:restore_key) { "MrMaliciousRestoreKey" }

      before do
        portfolio_item.discard
        undelete
      end

      it "returns a 403" do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when attempting to restore a portfolio_item that not been discarded' do
      it "returns a 404" do
        undelete
        expect(response).to have_http_status :not_found
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
    let(:permitted_params) { ActionController::Parameters.new(params).permit(:service_offering_ref) }

    before do
      allow(ServiceOffering::AddToPortfolioItem).to receive(:new).with(permitted_params).and_return(add_to_portfolio_svc)
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
      expect(response).to have_http_status(:not_found)
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

      expect(response).to have_http_status(:not_found)
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

  describe "copying portfolio items" do
    let(:copy_portfolio_item) do
      post "#{api("1.0")}/portfolio_items/#{portfolio_item.id}/copy", :params => params, :headers => default_headers
    end

    context "when copying into the same portfolio" do
      let(:params) { { :portfolio_id => portfolio.id } }

      before do
        copy_portfolio_item
      end

      it "returns a 200" do
        expect(response).to have_http_status(:ok)
      end

      it "returns a copy of the portfolio_item" do
        expect(json["description"]).to eq portfolio_item.description
        expect(json["owner"]).to eq portfolio_item.owner
        expect(json["workflow_ref"]).to eq portfolio_item.workflow_ref
      end

      it "modifies the name to not collide" do
        expect(json["name"]).to_not eq portfolio_item.name
        expect(json["name"]).to match(/^Copy of.*/)
      end
    end

    context "when copying with a specified name" do
      let(:params) { { :portfolio_item_name => "NewPortfolioItem" } }

      it "returns the name specified" do
        copy_portfolio_item
        expect(json["name"]).to eq params[:portfolio_item_name]
      end
    end

    context "when copying into a different portfolio" do
      let(:params) { { :portfolio_id => new_portfolio.id } }
      let(:new_portfolio) { create(:portfolio, :tenant_id => tenant.id) }

      before do
        copy_portfolio_item
      end

      it "returns a 200" do
        expect(response).to have_http_status(:ok)
      end

      it "returns a copy of the portfolio_item" do
        expect(json["description"]).to eq portfolio_item.description
        expect(json["owner"]).to eq portfolio_item.owner
        expect(json["workflow_ref"]).to eq portfolio_item.workflow_ref
      end

      it "does not modify the name" do
        expect(json["name"]).to eq portfolio_item.name
      end
    end

    context "when copying into a different portfolio in a different tenant" do
      let(:params) { { :portfolio_id => not_my_portfolio.id } }
      let(:not_my_portfolio) { create(:portfolio) }

      before do
        copy_portfolio_item
      end

      it 'returns a 422' do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
