describe 'Group Seed API', :type => :request do
  let(:tenant_id) { create(:tenant).id }
  let(:api_instance) { double }
  let(:rbac_seed) { instance_double(RBAC::Seed, :process => true) }
  let(:group1) { instance_double(RBACApiClient::GroupOut, :uuid => "123") }
  let(:org_admin) do
    false_hash = default_user_hash
    false_hash["identity"]["user"]["is_org_admin"] = true
    false_hash
  end
  let(:response_headers) { {"Content-Type" => 'application/json'} }
  let(:data) do
    [{
      :name        => "Catalog Administrators",
      :description => "Catalog Administrators have complete access to all objects in the Catalog Service."
    },
    {
      :name        => "Catalog Users",
      :description => "Catalog Users have limited access and can only order portfolios."
    }]
  end
  let(:count) { 1 }
  let(:catalog_admin) do
    { :data => data, :meta => { :count => count } }
  end
  let(:valid_attributes) { { :catalog => '1' } }

  around do |example|
    with_modified_env(:RBAC_URL => "http://localhost") do
      ManageIQ::API::Common::Request.with_request(modified_request(org_admin)) { example.call }
    end
  end

  describe 'POST /tenants/:id/seed' do
    context "when the group was previously not seeded" do
      let(:catalog_admin) do
        { :data => [], :meta => { :count => 0 } }
      end
      before do
        allow(api_instance).to receive(:list_group).with(group1.uuid).and_return(catalog_admin.to_json)
        allow(RBAC::Seed).to receive(:new).and_return(rbac_seed)
        stub_request(:get, "http://localhost/api/rbac/v1/groups/")
          .to_return(:status  => 200,
                     :body    => catalog_admin.to_json,
                     :headers => response_headers)
      end
      before { post "#{api}/tenants/#{tenant_id}/seed", :params => valid_attributes, :headers => modified_headers(org_admin) }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
        expect(JSON.parse(response.body)['message']).to eq "Tenant #{org_admin['identity']['account_number']} seeded"
      end

      it 'account number is populated in the RbacSeed table' do
        expect(RbacSeed.find_by(:external_tenant => org_admin['identity']['account_number'])).to be_truthy
      end
    end

    context "when the group already has been seeded" do
      before do
        RbacSeed.create!(:external_tenant => org_admin['identity']['account_number'])
        allow(api_instance).to receive(:list_group).with(group1.uuid).and_return(catalog_admin.to_json)
        stub_request(:get, "http://localhost/api/rbac/v1/groups/")
          .to_return(:status  => 204,
                     :body    => catalog_admin.to_json,
                     :headers => response_headers)
      end
      before { post "#{api}/tenants/#{tenant_id}/seed", :params => valid_attributes, :headers => modified_headers(org_admin) }

      it 'returns status code 204' do
        expect(response).to have_http_status(204)
        expect(response.body).to eq ""
      end

      it 'account number is in RbacSeed table' do
        expect(RbacSeed.find_by(:external_tenant => org_admin['identity']['account_number'])).to be_truthy
        #get "#{api}/rbac/seeded", :params => valid_attributes, :headers => modified_headers(org_admin)
        #expect(response.body).to eq "true"
      end
    end
  end
end
