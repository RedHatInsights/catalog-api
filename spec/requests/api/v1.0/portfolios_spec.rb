require 'securerandom'
describe "v1.0 - Portfolios API", :type => [:request, :v1] do
   let!(:portfolio)       { create(:portfolio) }
  let!(:portfolio_item)  { create(:portfolio_item, :portfolio => portfolio) }
  let!(:portfolio_items) { portfolio.portfolio_items << portfolio_item }
  let(:portfolio_id)     { portfolio.id }
  let(:bad_portfolio_id) { portfolio.id + 1}
  let(:catalog_access) { instance_double(Insights::API::Common::RBAC::Access, :scopes => %w[admin]) }
  before do
     allow(Insights::API::Common::RBAC::Access).to receive(:new).and_return(catalog_access)
     allow(catalog_access).to receive(:process).and_return(catalog_access)
     allow(catalog_access).to receive(:accessible?).with("portfolios", "create").and_return(true)
  end

  describe "GET /portfolios/:portfolio_id" do
    before do
      get "#{api_version}/portfolios/#{portfolio_id}", :headers => default_headers
    end

    context 'when portfolios exist' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns portfolio requested' do
        expect(json).not_to be_empty
        expect(json['id']).to eq(portfolio_id.to_s)
        expect(json['created_at']).to eq(portfolio.created_at.iso8601)
      end
    end

    context 'when the portfolio does not exist' do
      let(:portfolio_id) { 0 }

      it "cannot be requested" do
        expect(response).to have_http_status(404)
      end
    end
  end

  describe "GET v1.0 /portfolios/:portfolio_id" do
    before do
      get "#{api_version}/portfolios/#{portfolio_id}", :headers => default_headers
    end

    context 'when portfolios exist' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns portfolio requested' do
        expect(json).not_to be_empty
        expect(json['id']).to eq(portfolio_id.to_s)
      end
    end
  end

  describe "GET /portfolios" do
    context "without filter" do
      before do
        get "#{api_version}/portfolios", :headers => default_headers
      end

      context 'when portfolios exist' do
        it 'returns status code 200' do
          expect(response).to have_http_status(200)
        end

        it 'returns all portfolio requests' do
          expect(json['data'].size).to eq(1)
        end
      end
    end

    context "with filter" do
      let!(:portfolio_filter1) { create(:portfolio, :name => "testfilter1") }
      let!(:portfolio_filter2) { create(:portfolio, :name => "testfilter2") }

      it 'returns only the id specified in the filter' do
        get "#{api_version}/portfolios?filter[id]=#{portfolio_id}", :headers => default_headers

        expect(json["meta"]["count"]).to eq 1
        expect(json["data"].first["id"]).to eq portfolio_id.to_s
      end

      it 'allows filtering by name via regex' do
        get "#{api_version}/portfolios?filter[name][starts_with]=test", :headers => default_headers

        expect(json["meta"]["count"]).to eq 2

        names = json["data"].each.collect { |item| item["name"] }
        expect(names).to match_array [portfolio_filter1.name, portfolio_filter2.name]
      end
    end
  end

  describe '/portfolios', :type => :routing do
    let(:valid_attributes) { { :name => 'rspec 1', :description => 'rspec 1 description' } }
    context 'with wrong header' do
      it 'returns a 404' do
        expect(:post => "/portfolios").not_to be_routable
      end
    end
  end

  describe 'DELETE /portfolios/:portfolio_id' do
    let(:valid_attributes) { { :name => 'PatchPortfolio', :description => 'description for patched portfolio' } }

    context 'when discarding a portfolio' do
      before do
        delete "#{api_version}/portfolios/#{portfolio_id}", :headers => default_headers, :params => valid_attributes
      end

      it 'deletes the record' do
        expect(response).to have_http_status(:ok)
      end

      it 'sets the discarded_at column' do
        expect(Portfolio.with_discarded.find_by(:id => portfolio_id).discarded_at).to_not be_nil
      end

      it 'allows adding portfolios with the same name when one is discarded' do
        post "#{api_version}/portfolios", :headers => default_headers, :params => valid_attributes

        expect(response).to have_http_status(:ok)
      end

      it 'returns the restore_key in the body' do
        expect(json["restore_key"]).to eq Digest::SHA1.hexdigest(Portfolio.with_discarded.find(portfolio_id).discarded_at.to_s)
      end
    end

    context "when discarding portfolio_items fails" do
      before do
        allow(Portfolio).to receive(:find).with(portfolio.id.to_s).and_return(portfolio)
        allow(portfolio_item).to receive(:discard).and_return(false)
      end

      it 'reports errors when discarding child portfolio_items fails' do
        delete "#{api_version}/portfolios/#{portfolio_id}", :headers => default_headers, :params => valid_attributes

        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe "GET /portfolios/:portfolio_id/undelete" do
    let(:restore_key) { Digest::SHA1.hexdigest(portfolio.discarded_at.to_s) }
    let(:params) { { :restore_key => restore_key } }

    before do
      portfolio.discard
    end

    context "when restoring a portfolio" do
      before do
        post "#{api_version}/portfolios/#{portfolio_id}/undelete", :headers => default_headers, :params => params
      end

      it "returns a 200" do
        expect(response).to have_http_status :ok
      end

      it "returns the restored record" do
        expect(json["id"]).to eq portfolio.id.to_s
        expect(json["name"]).to eq portfolio.name
      end
    end

    context "when restoring a portfolio with the wrong restore key" do
      let(:restore_key) { "MrMaliciousRestoreKey" }

      before do
        portfolio.discard
        post "#{api_version}/portfolios/#{portfolio_id}/undelete", :headers => default_headers, :params => params
      end

      it "returns a 403" do
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when restoring the portfolio_items fails" do
      before do
        allow(Portfolio).to receive(:with_discarded).and_return(Portfolio)
        allow(Portfolio).to receive(:discarded).and_return(Portfolio)
        allow(Portfolio).to receive(:find).with(portfolio.id.to_s).and_return(portfolio)

        allow(PortfolioItem).to receive(:with_discarded).and_return(PortfolioItem)
        allow(PortfolioItem).to receive(:discarded).and_return([portfolio_item])
        allow(portfolio_item).to receive(:undiscard).and_return(false)
      end

      it 'reports errors when undiscarding the child portfolio_items fails' do
        post "#{api_version}/portfolios/#{portfolio_id}/undelete", :headers => default_headers, :params => params

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "when restoring a portfolio with portfolio_items that were discarded previously" do
      let!(:second_item) { create(:portfolio_item, :portfolio => portfolio, :discarded_at => 1.minute.ago) }

      before do
        portfolio.discard
      end

      it "only undeletes the one that was discarded at the same time as the portfolio" do
        post "#{api_version}/portfolios/#{portfolio_id}/undelete", :headers => default_headers, :params => params

        second_item.reload
        expect(second_item.discarded?).to be_truthy
      end
    end
  end

  describe 'PATCH /portfolios/:portfolio_id' do
    let(:valid_attributes) { { :name => 'PatchPortfolio', :description => 'description for patched portfolio' } }
    let(:invalid_attributes) { { :fred => 'nope', :bob => 'bob portfolio' } }
    let(:partial_attributes) { { :name => 'Chef Pisghetti' } }
    context 'when patched portfolio is valid' do
      before do
        patch "#{api_version}/portfolios/#{portfolio_id}", :headers => default_headers, :params => valid_attributes
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns an updated portfolio object' do
        expect(json).not_to be_empty
        expect(json).to be_a Hash
        expect(json['name']).to eq valid_attributes[:name]
      end
    end

    context 'when patched portfolio has openapi nullable values' do
      let(:nullable_attributes) { { :name => 'PatchPortfolio', :description => 'description for patched portfolio' } }
      before do
        patch "#{api_version}/portfolios/#{portfolio_id}", :headers => default_headers, :params => nullable_attributes
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns an updated portfolio object' do
        expect(json).not_to be_empty
        expect(json).to be_a Hash
      end
    end

    context 'when patched portfolio params are invalid' do
      before do
        patch "#{api_version}/portfolios/#{portfolio_id}", :headers => default_headers, :params => invalid_attributes
      end

      it 'returns status code 400' do
        expect(response).to have_http_status(400)
        expect(first_error_detail).to match(/found unpermitted parameters: :fred, :bob/)
      end
    end

    context 'when patched portfolio params are partial' do
      before do
        patch "#{api_version}/portfolios/#{portfolio_id}", :headers => default_headers, :params => partial_attributes
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
        expect(json['name']).to eq(partial_attributes[:name])
      end
    end
  end

  describe 'POST /portfolios' do
    let(:valid_attributes) { { :name => 'rspec 1', :description => 'rspec 1 description' } }
    context 'when portfolio attributes are valid' do
      before { post "#{api_version}/portfolios", :params => valid_attributes, :headers => default_headers }

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns the new portfolio' do
        expect(json['name']).to eq valid_attributes[:name]
      end

      it 'returns a status code 400 when trying to create with the same name' do
        post "#{api_version}/portfolios", :params => valid_attributes, :headers => default_headers

        expect(response).to have_http_status(400)
      end

      it 'stores the username in the owner column' do
        expect(json['owner']).to eq default_username
      end
    end

    context 'when portfolio attributes are not valid' do
      let(:invalid_attributes) { { :name => 'rspec 1', :description => 'rspec 1 description', :icon_id => "17" } }

      before { post "#{api_version}/portfolios", :params => invalid_attributes, :headers => default_headers }

      it 'returns status code 400' do
        expect(response).to have_http_status(400)
      end

      it 'warns about unpermitted field' do
        expect(first_error_detail).to match(/unpermitted.*icon_id/)
      end
    end

    context 'length restrictions' do
      let(:invalid_attributes) { { :name => 'a'*65, :description => 'rspec 1 description' } }
      before { post "#{api_version}/portfolios", :params => invalid_attributes, :headers => default_headers }

      it 'returns status code 400' do
        expect(response).to have_http_status(400)
        expect(first_error_detail).to match(/is longer than max length/)
      end
    end

    context 'share_info' do
      let(:portfolio) { create(:portfolio) }
      let(:uuid) { "123" }
      let(:group_names) { {"123" => "group_name"} }

      let(:share_info) { instance_double(Api::V1x0::Catalog::ShareInfo, :result => result) }
      let(:result) { [:group_name => "group_name", :group_uuid => "123", :permissions => %w[read update]] }

      before do
        allow(Api::V1x0::Catalog::ShareInfo).to receive(:new).with(:object => portfolio, :user_context => an_instance_of(UserContext)).and_return(share_info)
        allow(share_info).to receive(:process).and_return(share_info)
      end

      it "returns the sharing information" do
        get "#{api_version}/portfolios/#{portfolio.id}/share_info", :headers => default_headers
        expect(json.pluck('group_uuid')).to match_array(["123"])
        expect(json.pluck('group_name')).to match_array(["group_name"])
        expect(json.pluck('permissions')).to match_array([%w[read update]])
      end
    end

    context "copy without specifying name" do
      before do
        post "#{api_version}/portfolios/#{portfolio.id}/copy", :headers => default_headers
      end

      it "returns a 200" do
        expect(response).to have_http_status(:ok)
      end

      it "returns a copy of the portfolio" do
        expect(json["id"]).to_not eq portfolio.id
        expect(json["name"]).to match(/^Copy of.*/)
      end

      it "copies the fields completely" do
        expect(json["description"]).to eq portfolio.description
        expect(json["owner"]).to eq portfolio.owner
      end

      it "copies the portfolio item over" do
        item = PortfolioItem.find(Portfolio.find(json["id"]).portfolio_items.first.id)

        expect(item.name).to eq portfolio_item.name
        expect(item.description).to eq portfolio_item.description
        expect(item.owner).to eq portfolio_item.owner
      end
    end

    context "copy when specifying name" do
      let(:params) { { :portfolio_name => "NameyMcNameFace" } }

      before do
        post "#{api_version}/portfolios/#{portfolio.id}/copy", :params => params, :headers => default_headers
      end

      it "sets the name properly" do
        expect(json["name"]).to eq params[:portfolio_name]
      end
    end
  end

  context "tagging endpoints" do
    let(:rbac_access) { instance_double(Catalog::RBAC::Access) }

    before do
      allow(Catalog::RBAC::Access).to receive(:new).and_return(rbac_access)
      allow(rbac_access).to receive(:update_access_check).and_return(true)
      allow(rbac_access).to receive(:approval_workflow_check).and_return(true)
    end

    it_behaves_like "controller that supports tagging endpoints" do
      let(:object_instance) { portfolio }
    end
  end
end
