describe "v1.0 - Group Seed API", :type => [:request, :v1] do
  let!(:tenant) { create(:tenant) }
  let!(:tenant_id) { tenant.id }
  let(:api_instance) { double }
  let(:rbac_seed) { instance_double(Insights::API::Common::RBAC::Seed, :process => true) }
  let(:group1) { instance_double(RBACApiClient::GroupOut, :uuid => "123") }
  let(:org_admin) do
    false_hash = default_user_hash
    false_hash["identity"]["user"]["is_org_admin"] = true
    false_hash
  end
  let(:response_headers) { {"Content-Type" => 'application/json'} }
  let(:data) do
    [
      { :uuid        => "some-random-uuid",
        :name        => "Catalog Administrators",
        :description => "Catalog Administrators have complete access to all objects in the Catalog Service." },
      { :name        => "Catalog Users",
        :description => "Catalog Users have limited access and can only order portfolios." }
    ]
  end
  let(:count) { 1 }
  let(:catalog_admin) do
    { :data => data, :meta => { :count => count } }
  end

  around do |example|
    with_modified_env(:RBAC_URL => "http://localhost") do
      Insights::API::Common::Request.with_request(modified_request(org_admin)) { example.call }
    end
  end

  describe 'GET /tenants' do
    before do
      allow(Insights::API::Common::RBAC::Roles).to receive(:assigned_role?).with(catalog_admin_role).and_return(true)
      get "#{api_version}/tenants", :headers => default_headers
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end

    it 'returns all scoped tenants' do
      expect(json["data"].first['external_tenant']).to eq tenant.external_tenant
      expect(json["data"].first['id']).to eq tenant.id.to_s
    end
  end

  describe 'POST /tenants/:id/seed' do
    context "when the group was previously not seeded" do
      let(:no_groups) do
        { :data => [], :meta => { :count => 0 } }
      end
      let(:principals) { {:principals => [{:username => default_username}]} }

      before do
        allow(api_instance).to receive(:list_group).with(group1.uuid).and_return(catalog_admin.to_json)
        allow(Insights::API::Common::RBAC::Seed).to receive(:new).and_return(rbac_seed)

        stub_request(:get, "http://localhost/api/rbac/v1/groups/")
          .to_return(:status  => 200,
                     :body    => no_groups.to_json,
                     :headers => response_headers)

        stub_request(:get, "http://localhost/api/rbac/v1/groups/?limit=10&name=Catalog%20Administrators&offset=0")
          .to_return(:status  => 200,
                     :body    => catalog_admin.to_json,
                     :headers => response_headers)

        stub_request(:post, "http://localhost/api/rbac/v1/groups/some-random-uuid/principals/")
          .with(:body => principals.to_json)
          .to_return(:status => 200, :body => "", :headers => response_headers)
      end
      before { post "#{api_version}/tenants/#{tenant_id}/seed", :headers => modified_headers(org_admin) }

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'calls out to the groups api twice' do
        expect(a_request(:get, /rbac\/v1\/groups/)).to have_been_made.twice
      end

      it 'account number is populated in the RbacSeed table' do
        expect(RbacSeed.find_by(:external_tenant => org_admin['identity']['account_number'])).to be_truthy
      end

      it 'adds the user to the catalog administrators group' do
        expect(a_request(:post, "http://localhost/api/rbac/v1/groups/some-random-uuid/principals/")).to have_been_made.once
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
      before { post "#{api_version}/tenants/#{tenant_id}/seed", :headers => modified_headers(org_admin) }

      it 'returns status code 204' do
        expect(response).to have_http_status(204)
        expect(response.body).to eq ""
      end

      it 'account number is in RbacSeed table' do
        expect(RbacSeed.seeded(Insights::API::Common::Request.current)).to be_truthy
      end

      it 'gets the current list of groups' do
        expect(a_request(:get, "http://localhost/api/rbac/v1/groups/")).to have_been_made.once
      end

      it 'does not add the user to catalog administrators' do
        expect(a_request(:post, "http://localhost/api/rbac/v1/groups/some-random-uuid/principals/")).not_to have_been_made
      end
    end

    context 'when the user is not an org admin' do
      let(:catalog_admin) do
        { :data => [], :meta => { :count => 0 } }
      end
      before do
        allow(api_instance).to receive(:list_group).with(group1.uuid).and_return(catalog_admin.to_json)
        allow(Insights::API::Common::RBAC::Seed).to receive(:new).and_return(rbac_seed)
        stub_request(:get, "http://localhost/api/rbac/v1/groups/")
          .to_return(:status  => 200,
                     :body    => catalog_admin.to_json,
                     :headers => response_headers)
      end
      before { post "#{api_version}/tenants/seed", :headers => default_headers }

      it 'returns status code 403' do
        require 'byebug'; byebug
        expect(response).to have_http_status(403)
      end
    end
  end
end
