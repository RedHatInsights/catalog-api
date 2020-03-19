describe "v1.1 - PortfoliosRequests", :type => [:request, :v1x1] do
  let!(:portfolio)       { create(:portfolio) }
  let!(:portfolio_item)  { create(:portfolio_item, :portfolio => portfolio) }
  let!(:portfolio_items) { portfolio.portfolio_items << portfolio_item }
  let(:portfolio_id)     { portfolio.id }
  let(:rbac_access) { instance_double(Catalog::RBAC::Access) }
  let(:admin_check) { true }
  let(:read_access_check) { true }
  let(:update_access_check) { true }

  before do
    allow(Catalog::RBAC::Access).to receive(:new).and_return(rbac_access)
    allow(rbac_access).to receive(:admin_check).and_return(admin_check)
    allow(rbac_access).to receive(:read_access_check).and_return(read_access_check)
    allow(rbac_access).to receive(:update_access_check).and_return(update_access_check)
  end

  describe "GET /portfolios/:portfolio_id #show" do
    before do
      get "#{api_version}/portfolios/#{portfolio_id}", :headers => default_headers
    end

    context "when the user is a catalog administrator" do
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

        it "returns true for all user capabilities" do
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
      end

      context 'when the portfolio does not exist' do
        let(:portfolio_id) { 0 }

        it "cannot be requested" do
          expect(response).to have_http_status(404)
        end
      end
    end

    context "when the user is not a catalog administrator" do
      let(:admin_check) { false }

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

        it "returns false for those user capabilities that are not allowed" do
          expect(json['metadata']['user_capabilities']).to eq(
            "copy"    => false,
            "create"  => false,
            "destroy" => false,
            "share"   => false,
            "show"    => true,
            "unshare" => false,
            "update"  => true
          )
        end
      end

      context 'when the portfolio does not exist' do
        let(:portfolio_id) { 0 }

        it "cannot be requested" do
          expect(response).to have_http_status(404)
        end
      end
    end
  end

  describe "GET /portfolios #index" do
    before do
      allow(Catalog::RBAC::Role).to receive(:catalog_administrator?).and_return(true)
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
end
