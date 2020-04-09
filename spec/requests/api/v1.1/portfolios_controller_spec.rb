describe "v1.1 - PortfoliosRequests", :type => [:request, :v1x1] do
  let!(:portfolio)       { create(:portfolio) }
  let!(:portfolio_item)  { create(:portfolio_item, :portfolio => portfolio) }
  let!(:portfolio_items) { portfolio.portfolio_items << portfolio_item }
  let(:portfolio_id)     { portfolio.id }
  let(:rbac_access)      { instance_double(Catalog::RBAC::Access) }

  before do
    allow(Catalog::RBAC::Access).to receive(:new).and_return(rbac_access)
    allow(rbac_access).to receive(:read_access_check).and_return(true)
    allow(rbac_access).to receive(:update_access_check).and_return(true)
    allow(rbac_access).to receive(:create_access_check).and_return(true)
    allow(rbac_access).to receive(:destroy_access_check).and_return(true)
  end

  describe "GET /portfolios/:portfolio_id #show" do
    before do
      create(:access_control_entry, :has_read_permission, :aceable_id => portfolio_id, :group_uuid => "456-123")
      get "#{api_version}/portfolios/#{portfolio_id}", :headers => default_headers
    end

    context 'when portfolios exist' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns portfolio requested with included metadata' do
        expect(json).not_to be_empty
        expect(json['id']).to eq(portfolio_id.to_s)
        expect(json['created_at']).to eq(portfolio.created_at.iso8601)
        expect(json['metadata']).to have_key('user_capabilities')
      end

      it "returns the user capabilities based on the allowed access" do
        expect(json['metadata']['user_capabilities']).to eq(
          "copy"    => true,
          "create"  => true,
          "destroy" => true,
          "share"   => true,
          "show"    => true,
          "unshare" => true,
          "update"  => true
        )
      end

      it "returns shared status" do
        expect(json['metadata']['shared']).to be_truthy
      end
    end

    context 'when the portfolio does not exist' do
      let(:portfolio_id) { 0 }

      it "cannot be requested" do
        expect(response).to have_http_status(404)
      end
    end
  end

  describe "GET /portfolios #index" do
    let(:catalog_access) { instance_double(Insights::API::Common::RBAC::Access, :scopes => %w[admin]) }

    before do
      allow(Insights::API::Common::RBAC::Access).to receive(:new).and_return(catalog_access)
      allow(catalog_access).to receive(:process).and_return(catalog_access)
      get "#{api_version}/portfolios", :headers => default_headers
    end

    context 'when portfolios exist' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all portfolio requests with included metadata' do
        expect(json['data'].size).to eq(1)
        expect(json['data'].first['metadata']).to have_key('user_capabilities')
      end
    end
  end

  describe "POST /portfolios #create" do
    let(:valid_attributes) { {:name => 'Fred', :description => "Fred's Portfolio" } }

    context "when the user has create access" do
      it 'creates a portfolio' do
        post "#{api_version}/portfolios", :headers => default_headers, :params => valid_attributes

        expect(response).to have_http_status(:ok)
      end
    end

    context "when the user does not have create access" do
      before do
        allow(rbac_access).to receive(:create_access_check).and_return(false)
      end

      it 'returns status code 403' do
        post "#{api_version}/portfolios", :headers => default_headers, :params => valid_attributes

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "PATCH /portfolios #update" do
    let!(:portfolio1) { create(:portfolio) }
    let(:updated_attributes) { {:name => 'Barney', :description => "Barney's Portfolio" } }

    context "user has update permission" do
      it 'only allows updating a specific portfolio' do
        patch "#{api_version}/portfolios/#{portfolio1.id}", :headers => default_headers, :params => updated_attributes
        expect(response).to have_http_status(:ok)
      end
    end

    context "user has read only permission for a specific portfolio" do
      before do
        allow(rbac_access).to receive(:update_access_check).and_return(false)
      end

      it 'fails updating a portfolio' do
        patch "#{api_version}/portfolios/#{portfolio1.id}", :headers => default_headers, :params => updated_attributes
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "DELETE /portfolios #delete" do
    it "allows deletion of any portfolio" do
      delete "#{api_version}/portfolios/#{portfolio.id}", :headers => default_headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /portfolios/:portfolio_id/copy #copy" do
    it 'returns a 200' do
      post "#{api_version}/portfolios/#{portfolio.id}/copy", :headers => default_headers
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /portfolios/:portfolio_id/share #share" do
    let(:group_uuid) { SecureRandom.uuid }
    let(:params) do
      {:group_uuids => [group_uuid], :permissions => ["read"]}
    end
    let(:share_resource) { instance_double(Catalog::ShareResource) }
    let(:options) do
      {
        :object => portfolio,
        :permissions => ["read"],
        :group_uuids => [group_uuid]
      }
    end

    subject do
      post "#{api_version}/portfolios/#{portfolio.id}/share", :params => params, :headers => default_headers
    end

    before do
      allow(Catalog::ShareResource).to receive(:new).and_return(share_resource)
      allow(share_resource).to receive(:process)
    end

    it_behaves_like "action that tests authorization", :share?, Portfolio

    it "shares the resource" do
      expect(Catalog::ShareResource).to receive(:new).with(options)
      expect(share_resource).to receive(:process)

      subject
    end

    it "returns a 204" do
      subject

      expect(response).to have_http_status(:no_content)
    end

    context "bad group uuid" do
      let(:group_uuid) { "fred" }

      it "returns a 400" do
        subject

        expect(response).to have_http_status(:bad_request)
        expect(first_error_detail).to match(/OpenAPIParser::InvalidUUIDFormat/)
      end
    end
  end

  describe "POST /portfolios/:portfolio_id/unshare #unshare" do
    let(:group_uuid) { SecureRandom.uuid }
    let(:params) do
      {:group_uuids => [group_uuid], :permissions => ["read"]}
    end
    let(:unshare_resource) { instance_double(Catalog::UnshareResource) }
    let(:options) do
      {
        :object => portfolio,
        :permissions => ["read"],
        :group_uuids => [group_uuid]
      }
    end

    subject do
      post "#{api_version}/portfolios/#{portfolio.id}/unshare", :params => params, :headers => default_headers
    end

    before do
      allow(Catalog::UnshareResource).to receive(:new).and_return(unshare_resource)
      allow(unshare_resource).to receive(:process)
    end

    it_behaves_like "action that tests authorization", :unshare?, Portfolio

    it "unshares the resource" do
      expect(Catalog::UnshareResource).to receive(:new).with(options)
      expect(unshare_resource).to receive(:process)

      subject
    end

    it "returns a 204" do
      subject

      expect(response).to have_http_status(:no_content)
    end

    context "bad group uuid" do
      let(:group_uuid) { "fred" }

      it "returns a 400" do
        subject

        expect(response).to have_http_status(:bad_request)
        expect(first_error_detail).to match(/OpenAPIParser::InvalidUUIDFormat/)
      end
    end
  end
end
