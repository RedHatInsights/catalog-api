describe "OrderItemsRequests", :type => :request do
  include ServiceSpecHelper

  let(:order) { create(:order) }
  let!(:order_item) { create(:order_item, :order_id => order.id, :portfolio_item_id => portfolio_item.id) }
  let(:portfolio_item) { create(:portfolio_item, :service_offering_ref => "123") }

  context "v0.0" do
    it "lists order items" do
      get "/api/v0.0/orders/#{order.id}/items"

      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).first['id']).to eq(order_item.id.to_s)
    end
  end

  context "v0.1" do
    it "lists order items" do
      get "/api/v0.1/orders/#{order.id}/items"

      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['data'].first['id']).to eq(order_item.id.to_s)
    end
  end
end
