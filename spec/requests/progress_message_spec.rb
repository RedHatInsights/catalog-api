describe "ProgressMessageRequests", :type => :request do
  around do |example|
    bypass_rbac do
      example.call
    end
  end

  let(:order) { create(:order) }
  let!(:order_item) { create(:order_item, :order_id => order.id, :portfolio_item_id => portfolio_item.id) }
  let(:portfolio_item) { create(:portfolio_item, :service_offering_ref => "123") }
  let!(:progress_message) { create(:progress_message, :order_item_id => order_item.id.to_s) }

  context "v1.0" do
    describe "GET /order_items/:order_item_id/progress_messages" do
      it "lists progress messages" do
        get "/#{api}/order_items/#{order_item.id}/progress_messages", :headers => default_headers

        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['data'].first['message']).to eq(progress_message.message)
      end

      context "when the order item does not exist" do
        let(:order_item_id) { 0 }

        it "returns a 404" do
          get "/#{api}/order_items/#{order_item_id}/progress_messages", :headers => default_headers

          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(first_error_detail).to match(/Couldn't find OrderItem/)
        end
      end
    end
  end
end
