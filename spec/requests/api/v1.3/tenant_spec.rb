describe "v1.3 - Seed API", :type => [:request, :v1x3] do
  let!(:tenant) { create(:tenant) }
  let!(:tenant_id) { tenant.id }
  let(:org_admin) do
    false_hash = default_user_hash
    false_hash["identity"]["user"]["is_org_admin"] = true
    false_hash
  end
  let(:response_headers) { {"Content-Type" => 'application/json'} }
  let(:add_to_group) { instance_double(Api::V1x3::Catalog::AddToGroup) } 
  let(:seed_portfolio) { instance_double(Api::V1x3::Catalog::SeedPortfolios) }

  describe 'GET /tenants' do
    before { get "#{api_version}/tenants", :headers => modified_headers(org_admin) }

    it "not seeded" do
      expect(response).to have_http_status(200)
      expect(JSON.parse(response.body)['data'][0]['seeded']).to be_falsey
    end
  end

  describe 'POST /tenants/:id/seed' do
    context "when the group was previously not seeded" do

      before do
        allow(Api::V1x3::Catalog::SeedPortfolios).to receive(:new).and_return(seed_portfolio)
        allow(Api::V1x3::Catalog::AddToGroup).to receive(:new).and_return(add_to_group)
        allow(seed_portfolio).to receive(:process).and_return(seed_portfolio)
        allow(add_to_group).to receive(:process).and_return(add_to_group)
      end

      before { post "#{api_version}/tenants/#{tenant_id}/seed", :headers => modified_headers(org_admin) }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
        tenant.reload
        expect(tenant.seeded).to be_truthy
      end
    end

    context "when the group already has been seeded" do
      before do
        tenant.update_attributes!(:seeded => true)
        tenant.save
      end
      before { post "#{api_version}/tenants/#{tenant_id}/seed", :headers => modified_headers(org_admin) }

      it 'returns status code 204' do
        expect(response).to have_http_status(204)
      end
    end

    context 'when the user is not an org admin' do
      before { post "#{api_version}/tenants/#{tenant_id}/seed", :headers => default_headers }

      it 'returns status code 403' do
        expect(response).to have_http_status(403)
      end
    end
  end
end
