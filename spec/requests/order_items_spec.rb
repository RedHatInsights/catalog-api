describe "OrderItemsRequests", :type => :request do
  around do |example|
    bypass_tenancy do
      example.call
    end
  end

  let(:order) { create(:order) }
  let!(:order_item) { create(:order_item, :order_id => order.id, :portfolio_item_id => portfolio_item.id) }
  let(:portfolio_item) { create(:portfolio_item, :service_offering_ref => "123") }

  context "v1" do
    it "lists order items" do
      get "/api/v1.0/orders/#{order.id}/order_items"

      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['data'].first['id']).to eq(order_item.id.to_s)
    end
  end
end
