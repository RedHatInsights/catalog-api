describe "v1.2 - PortfolioItemRequests", :type => [:request, :topology, :v1x2] do
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

  describe "GET /portfolio_items/:portfolio_item_id #show with showDiscarded query" do
    let(:portfolio_item_orderable) { instance_double(Api::V1x1::Catalog::PortfolioItemOrderable, :result => true) }

    before do
      allow(Api::V1x1::Catalog::PortfolioItemOrderable).to receive(:new).with(portfolio_item).and_return(portfolio_item_orderable)
      allow(portfolio_item_orderable).to receive(:process).and_return(portfolio_item_orderable)
      delete "#{api_version}/portfolio_items/#{portfolio_item_id}", :headers => default_headers
      get "#{api_version}/portfolio_items/#{portfolio_item_id}", :params => params, :headers => default_headers
    end

    context 'when showDiscarded is true' do
      let(:params) { {:showDiscarded => true} }

      it 'return 200' do
        expect(response).to have_http_status(200)
        expect(json["id"]).to eq portfolio_item_id
      end
    end

    context 'when showDiscarded is false' do
      let(:params) { {:showDiscarded => false} }

      it 'return 404' do
        expect(response).to have_http_status(404)
      end
    end
  end
end
