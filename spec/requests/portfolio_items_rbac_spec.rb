describe 'Portfolio Items RBAC API' do
  let(:tenant) { create(:tenant) }
  let(:portfolio) { create(:portfolio, :tenant_id => tenant.id) }
  let!(:portfolio_item1) { create(:portfolio_item, :portfolio_id => portfolio.id, :tenant_id => tenant.id) }
  let!(:portfolio_item2) { create(:portfolio_item, :tenant_id => tenant.id) }
  let(:access_obj) { instance_double(RBAC::Access, :accessible? => true, :owner_scoped? => true, :id_list => [portfolio_item1.id.to_s]) }
  let(:double_access_obj) { instance_double(RBAC::Access, :accessible? => true, :owner_scoped? => true, :id_list => [portfolio_item1.id.to_s, portfolio_item2.id.to_s]) }

  let(:block_access_obj) { instance_double(RBAC::Access, :accessible? => false) }

  describe "GET /portfolio_items" do
    it 'returns status code 200' do
      allow(RBAC::Access).to receive(:new).with('portfolio_items', 'read').and_return(access_obj)
      allow(access_obj).to receive(:process).and_return(access_obj)
      get "#{api('1.0')}/portfolio_items", :headers => default_headers

      expect(response).to have_http_status(200)
      result = JSON.parse(response.body)
      expect(result['data'][0]['id']).to eq(portfolio_item1.id.to_s)
    end

    it 'returns status code 403' do
      allow(RBAC::Access).to receive(:new).with('portfolio_items', 'read').and_return(block_access_obj)
      allow(block_access_obj).to receive(:process).and_return(block_access_obj)
      get "#{api('1.0')}/portfolio_items", :headers => default_headers

      expect(response).to have_http_status(403)
    end
  end

  context "when user does not have RBAC write portfolios access" do
    before do
      allow(RBAC::Access).to receive(:new).with('portfolio_items', 'read').and_return(access_obj)
      allow(access_obj).to receive(:process).and_return(access_obj)

      allow(RBAC::Access).to receive(:new).with('portfolios', 'write').and_return(block_access_obj)
      allow(block_access_obj).to receive(:process).and_return(block_access_obj)
    end

    it 'returns a 403' do
      post "#{api("1.0")}/portfolio_items/#{portfolio_item1.id}/copy", :headers => default_headers

      expect(response).to have_http_status(403)
    end
  end

  context "when user has RBAC write portfolios access" do
    let(:portfolio_access_obj) { instance_double(RBAC::Access, :accessible? => true, :owner_scoped? => true, :id_list => [portfolio.id.to_s]) }
    before do
      allow(RBAC::Access).to receive(:new).with('portfolio_items', 'read').and_return(access_obj)
      allow(access_obj).to receive(:process).and_return(access_obj)

      allow(RBAC::Access).to receive(:new).with('portfolios', 'write').and_return(portfolio_access_obj)
      allow(portfolio_access_obj).to receive(:process).and_return(portfolio_access_obj)
    end

    it 'returns a 200' do
      post "#{api("1.0")}/portfolio_items/#{portfolio_item1.id}/copy", :headers => default_headers

      expect(response).to have_http_status(:ok)
    end
  end
end
