describe "v1.3 - ProgressMessageRequests", :type => [:request, :v1x3] do
  let(:order) { create(:order) }
  let!(:order_item) { create(:order_item, :order_id => order.id, :portfolio_item_id => portfolio_item.id) }
  let(:portfolio_item) { create(:portfolio_item, :service_offering_ref => "123") }
  let!(:progress_message) { create(:progress_message, :message => "order item message", :order_item_id => order_item.id.to_s) }
  let!(:order_progress_message) { create(:progress_message, :message => "order message", :order_id => order.id.to_s) }

  describe "v1.3" do
    context "GET /orders/:order_id/progress_messages" do
      let(:params) { {:source_type => "Order"} }

      it "lists progress messages" do
        get "#{api_version}/orders/#{order.id}/progress_messages", :headers => default_headers, :params => params

        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['data'].first['message']).to eq(order_progress_message.message)
      end

      context "when params are invalid" do
        let(:params) { {:source_type => "OrderItem"} }

        it "returns a 404" do
          get "#{api_version}/orders/#{order.id}/progress_messages", :headers => default_headers, :params => params

          expect(response.status).to eq(400)
          expect(first_error_detail).to match(/Catalog::InvalidParameter/)
        end
      end
    end

    context "GET /order_items/:order_item_id/progress_messages" do
      let(:params) { {:source_type => "OrderItem"} }

      it "lists progress messages" do
        get "#{api_version}/order_items/#{order_item.id}/progress_messages", :headers => default_headers

        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['data'].first['message']).to eq(progress_message.message)
      end

      context "when the order item does not exist" do
        let(:order_item_id) { 0 }

        it "returns a 404" do
          get "#{api_version}/order_items/#{order_item_id}/progress_messages", :headers => default_headers, :params => params

          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:not_found)
          expect(first_error_detail).to match(/Couldn't find OrderItem/)
        end
      end
    end
  end
end
