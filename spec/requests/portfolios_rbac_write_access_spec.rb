describe 'Portfolios Write Access RBAC API' do
  let(:tenant) { create(:tenant, :external_tenant => default_user_hash['identity']['account_number']) }
  let!(:portfolio1) { create(:portfolio, :tenant_id => tenant.id) }
  let!(:portfolio2) { create(:portfolio, :tenant_id => tenant.id) }
  let(:access_obj) { instance_double(RBAC::Access, :accessible? => true) }
  let(:valid_attributes) { {:name => 'Fred', :description => "Fred's Portfolio" } }

  let(:block_access_obj) { instance_double(RBAC::Access, :accessible? => false) }

  describe "POST /portfolios" do
    it 'creates a portfolio' do
      allow(RBAC::Access).to receive(:new).with('portfolios', 'write').and_return(access_obj)
      allow(access_obj).to receive(:process).and_return(access_obj)
      post "#{api('1.0')}/portfolios", :headers => default_headers, :params => valid_attributes

      expect(response).to have_http_status(:ok)
    end

    it 'returns status code 403' do
      allow(RBAC::Access).to receive(:new).with('portfolios', 'write').and_return(block_access_obj)
      allow(block_access_obj).to receive(:process).and_return(block_access_obj)
      post "#{api('1.0')}/portfolios", :headers => default_headers, :params => valid_attributes

      expect(response).to have_http_status(:forbidden)
    end
  end
end
