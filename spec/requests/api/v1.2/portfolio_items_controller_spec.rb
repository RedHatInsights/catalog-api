describe "v1.2 - PortfolioItemRequests", :type => [:request, :topology, :v1x2] do
  let!(:portfolio) { create(:portfolio) }
  let(:portfolio_id) { portfolio.id.to_s }
  let(:portfolio_items) { create_list(:portfolio_item, 2, :portfolio_id => portfolio_id) }
  let(:portfolio_item_id) { portfolio_items.first.id.to_s }
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
      allow(Api::V1x1::Catalog::PortfolioItemOrderable).to receive(:new).and_return(portfolio_item_orderable)
      allow(portfolio_item_orderable).to receive(:process).and_return(portfolio_item_orderable)
      delete "#{api_version}/portfolio_items/#{portfolio_items.first.id}", :headers => default_headers
      get "#{api_version}/portfolio_items/#{portfolio_item_id}", :params => params, :headers => default_headers
    end

    context 'when show_discarded is true' do
      let(:params) { {:show_discarded => true} }

      context 'when get discarded item' do
        let(:portfolio_item_id) { portfolio_items.first.id }

        it 'return 200' do
          expect(response).to have_http_status(200)
          expect(json["id"]).to eq portfolio_item_id.to_s
          expect(json["metadata"]["orderable"]).to eq(false)
        end
      end

      context 'when get normal item' do
        let(:portfolio_item_id) { portfolio_items.second.id }

        it 'return 200' do
          expect(response).to have_http_status(200)
          expect(json["id"]).to eq portfolio_items.second.id.to_s
          expect(json["metadata"]["orderable"]).to eq(true)
        end
      end
    end

    context 'when show_discarded is false' do
      let(:params) { {:show_discarded => false} }

      it 'return 404' do
        expect(response).to have_http_status(404)
      end
    end
  end
end
