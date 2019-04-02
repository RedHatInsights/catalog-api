describe "OrderItemsRequests", :type => :request do
  let(:tenant) { create(:tenant, :external_tenant => default_user_hash['identity']['account_number']) }
  let!(:order) { create(:order, :tenant_id => tenant.id) }
  let!(:order_item) { create(:order_item, :order_id => order.id, :portfolio_item_id => portfolio_item.id, :tenant_id => tenant.id) }
  let(:portfolio_item) { create(:portfolio_item, :service_offering_ref => "123", :tenant_id => tenant.id) }

  context "v1" do
    it "lists order items" do
      get "/api/v1.0/orders/#{order.id}/order_items", :headers => default_headers

      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['data'].first['id']).to eq(order_item.id.to_s)
    end
  end

  describe "#approval_requests" do
    let!(:approval) { create(:approval_request, :order_item_id => order_item.id, :workflow_ref => "1") }

    context "list" do
      before do
        get "#{api}/order_items/#{order_item.id}/approval_requests", :headers => default_headers
      end

      it "returns a 200 http status" do
        expect(response).to have_http_status(:ok)
      end

      it "lists approval requests" do
        expect(json["data"].count).to eq 1
        expect(json["data"].first["id"]).to eq approval.id.to_s
      end
    end
  end
end
