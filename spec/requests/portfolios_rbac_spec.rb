describe 'Portfolios RBAC API' do
  let(:tenant) { create(:tenant, :external_tenant => default_user_hash['identity']['account_number']) }
  let!(:portfolio1) { create(:portfolio, :tenant_id => tenant.id) }
  let!(:portfolio2) { create(:portfolio, :tenant_id => tenant.id) }
  let(:access_obj) { instance_double(RBAC::Access, :owner_scoped? => false, :accessible? => true, :id_list => [portfolio1.id.to_s]) }
  let(:double_access_obj) { instance_double(RBAC::Access, :owner_scoped? => false, :accessible? => true, :id_list => [portfolio1.id.to_s, portfolio2.id.to_s]) }

  let(:block_access_obj) { instance_double(RBAC::Access, :accessible? => false) }

  describe "GET /portfolios" do
    it 'returns status code 200' do
      allow(RBAC::Access).to receive(:new).with('portfolios', 'read').and_return(access_obj)
      allow(access_obj).to receive(:process).and_return(access_obj)
      get "#{api('1.0')}/portfolios", :headers => default_headers

      expect(response).to have_http_status(200)
      result = JSON.parse(response.body)
      expect(result['data'][0]['id']).to eq(portfolio1.id.to_s)
    end

    it 'returns status code 403' do
      allow(RBAC::Access).to receive(:new).with('portfolios', 'read').and_return(block_access_obj)
      allow(block_access_obj).to receive(:process).and_return(block_access_obj)
      get "#{api('1.0')}/portfolios", :headers => default_headers

      expect(response).to have_http_status(403)
    end

    context "with filtering" do
      before do
        allow(RBAC::Access).to receive(:new).with('portfolios', 'read').and_return(double_access_obj)
        allow(double_access_obj).to receive(:process).and_return(double_access_obj)
        get "#{api('1.0')}/portfolios?filter[name]=#{portfolio1.name}", :headers => default_headers
      end

      it 'returns a 200' do
        expect(response).to have_http_status(200)
      end

      it 'only returns the portfolio we filtered for' do
        result = JSON.parse(response.body)

        expect(result['meta']['count']).to eq 1
        expect(result['data'][0]['name']).to eq(portfolio1.name)
      end
    end
  end
end
