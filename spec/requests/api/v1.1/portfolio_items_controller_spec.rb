describe "v1.1 - PortfolioItemRequests", :type => [:request, :topology, :v1x1] do
  let!(:portfolio) { create(:portfolio) }
  let(:portfolio_id) { portfolio.id.to_s }
  let(:portfolio_item) { create(:portfolio_item, :portfolio_id => portfolio_id) }
  let(:portfolio_item_id) { portfolio_item.id.to_s }
  let(:rbac_access) { instance_double(Catalog::RBAC::Access) }

  before do
    allow(Catalog::RBAC::Access).to receive(:new).and_return(rbac_access)
    allow(rbac_access).to receive(:resource_check).with('read', portfolio.id, Portfolio).and_return(true)
    allow(rbac_access).to receive(:resource_check).with('update', portfolio.id, Portfolio).and_return(true)
    allow(rbac_access).to receive(:permission_check).with('read', Portfolio).and_return(true)
    allow(rbac_access).to receive(:approval_workflow_check).and_return(true)
  end

  describe "GET /portfolio_items/:portfolio_item_id #show" do
    subject { get "#{api_version}/portfolio_items/#{portfolio_item_id}", :headers => default_headers }
    let(:portfolio_item_orderable) { instance_double(Api::V1x1::Catalog::PortfolioItemOrderable, :result => true) }

    before do |example|
      allow(Api::V1x1::Catalog::PortfolioItemOrderable).to receive(:new).with(portfolio_item).and_return(portfolio_item_orderable)
      allow(portfolio_item_orderable).to receive(:process).and_return(portfolio_item_orderable)
      subject unless example.metadata[:subject_inside]
    end

    context 'the portfolio_item exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns the portfolio_item we asked for' do
        expect(json["id"]).to eq portfolio_item_id
      end

      it 'portfolio item references parent portfolio' do
        expect(json["portfolio_id"]).to eq portfolio_id
      end

      it "returns the metadata" do
        expect(json["metadata"]["user_capabilities"]).to eq(
          "copy"         => true,
          "create"       => true,
          "destroy"      => true,
          "update"       => true,
          "edit_survey"  => true,
          "show"         => true,
          "set_approval" => true,
          "tag"          => true,
          "untag"        => true
        )
        expect(json["metadata"]["orderable"]).to eq(true)
      end

       it_behaves_like "action that tests authorization", :show?, PortfolioItem
    end

    context 'the portfolio_item does not exist' do
      let(:portfolio_item_id) { 0 }

      it "can't be requested" do
        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'GET /portfolio_items #index' do
    before do
      portfolio_item_policy_scope = PortfolioItemPolicy::Scope.new(nil, PortfolioItem)
      allow(PortfolioItemPolicy::Scope).to receive(:new).and_return(portfolio_item_policy_scope)
      allow(portfolio_item_policy_scope).to receive(:resolve).and_return(PortfolioItem.all)
    end

    it "success" do
      portfolio_item
      get "#{api_version}/portfolio_items", :headers => default_headers
      expect(response).to have_http_status(200)
      expect(json['data'].count).to eq(1)
      expect(json['data'].first['metadata']).to have_key("user_capabilities")
    end
  end
end
