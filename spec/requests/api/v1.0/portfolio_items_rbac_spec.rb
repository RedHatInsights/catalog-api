describe "v1.0 - Portfolio Items RBAC API", :type => [:request, :v1] do
  let(:portfolio) { create(:portfolio) }
  let!(:portfolio_item1) { create(:portfolio_item, :portfolio => portfolio) }
  let!(:portfolio_item2) { create(:portfolio_item) }
  let(:rbac_access) { instance_double(Catalog::RBAC::Access) }
  let(:access_control_entries) { instance_double(Catalog::RBAC::AccessControlEntries) }

  before do
    allow(Catalog::RBAC::Access).to receive(:new).and_return(rbac_access)
    allow(Catalog::RBAC::AccessControlEntries).to receive(:new).and_return(access_control_entries)
    allow(Catalog::RBAC::Role).to receive(:catalog_administrator?).and_return(false)
    allow(rbac_access).to receive(:permission_check).with('read', Portfolio).and_return(true)
    allow(rbac_access).to receive(:resource_check).with('update', portfolio.id, Portfolio).and_return(true)
    allow(rbac_access).to receive(:resource_check).with('read', portfolio.id, Portfolio).and_return(true)
  end

  describe "GET /portfolio_items" do
    it 'returns status code 200' do
      allow(access_control_entries).to receive(:ace_ids).with('read', Portfolio).and_return([portfolio.id])
      get "#{api_version}/portfolio_items", :headers => default_headers

      expect(response).to have_http_status(200)
      result = JSON.parse(response.body)
      expect(result['data'][0]['id']).to eq(portfolio_item1.id.to_s)
    end

    it 'returns status code 403' do
      allow(rbac_access).to receive(:permission_check).with('read', Portfolio).and_return(false)
      get "#{api_version}/portfolio_items", :headers => default_headers

      expect(response).to have_http_status(403)
    end
  end

  context "when user does not have RBAC update portfolios access" do
    before do
      allow(rbac_access).to receive(:resource_check).with('update', portfolio.id, Portfolio).and_return(false)
    end

    it 'returns a 403' do
      post "#{api_version}/portfolio_items/#{portfolio_item1.id}/copy", :headers => default_headers
      expect(response).to have_http_status(403)
    end
  end

  context "when user has RBAC update portfolios access" do
    let(:portfolio_access_obj) { instance_double(Insights::API::Common::RBAC::Access, :accessible? => true, :owner_scoped? => false) }
    let(:rbac_access) { instance_double(Catalog::RBAC::Access) }

    before do
      allow(Catalog::RBAC::Access).to receive(:new).and_return(rbac_access)
      allow(rbac_access).to receive(:resource_check).with('read', portfolio.id, Portfolio).and_return(true)
      allow(rbac_access).to receive(:resource_check).with('update', portfolio.id, Portfolio).and_return(true)
    end

    it 'returns a 200' do
      post "#{api_version}/portfolio_items/#{portfolio_item1.id}/copy", :headers => default_headers

      expect(response).to have_http_status(:ok)
    end
  end
end
