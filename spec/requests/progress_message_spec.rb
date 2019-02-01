describe "ProgressMessageRequests", :type => :request do
  include ServiceSpecHelper

  let(:order) { create(:order) }
  let!(:order_item) { create(:order_item, :order_id => order.id, :portfolio_item_id => portfolio_item.id) }
  let(:portfolio_item) { create(:portfolio_item, :service_offering_ref => "123") }
  let!(:progress_message) { create(:progress_message, :order_item_id => order_item.id.to_s) }

  context "v0.0" do
    it "lists progress messages" do
      get "/api/v0.0/order_items/#{order_item.id}/progress_messages"

      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).first['id']).to eq(progress_message.id.to_s)
    end
  end

  context "v0.1" do
    it "lists progress messages" do
      get "/api/v0.1/order_items/#{order_item.id}/progress_messages"

      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['data'].first['id']).to eq(progress_message.id.to_s)
    end
  end
end
