describe "OrderItemsRequests", :type => :request do
  around do |example|
    bypass_rbac do
      example.call
    end
  end

  let!(:order_1) { create(:order) }
  let!(:order_2) { create(:order) }
  let!(:order_3) { create(:order) }
  let!(:order_item_1) { create(:order_item, :order => order_1) }
  let!(:order_item_2) { create(:order_item, :order => order_2) }
  let(:params) do
    { 'order_id'                    => order_1.id,
      'portfolio_item_id'           => order_item_1.portfolio_item.id,
      'count'                       => 1,
      'service_parameters'          => {'name' => 'fred'},
      'provider_control_parameters' => {'age' => 50},
      'service_plan_ref'            => '10' }
  end

  describe "CRUD" do
    context "when listing order_items" do
      describe "GET /orders/:order_id/order_items" do
        it "lists order items under an order" do
          get "/api/v1.0/orders/#{order_1.id}/order_items", :headers => default_headers

          expect(response.content_type).to eq("application/json")
          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)['data'].first['id']).to eq(order_item_1.id.to_s)
        end

        context "when the order does not exist" do
          let(:order_id) { 0 }

          it "returns a 404" do
            get "/api/v1.0/orders/#{order_id}/order_items", :headers => default_headers

            expect(response.content_type).to eq("application/json")
            expect(JSON.parse(response.body)["message"]).to eq("Not Found")
            expect(response).to have_http_status(:not_found)
          end
        end

        context "after an order has an order item created under it" do
          before do
            ManageIQ::API::Common::Request.with_request(default_request) do
              post "/api/v1.0/orders/#{order_3.id}/order_items", :headers => default_headers, :params => params
            end
          end

          it "stores the x-rh-insights-id from the headers" do
            get "/api/v1.0/orders/#{order_3.id}/order_items", :headers => default_headers
            expect(json["data"].first["insights_request_id"]).to eq default_headers["x-rh-insights-request-id"]
          end
        end
      end

      it "list all order items by tenant" do
        get "/api/v1.0/order_items", :headers => default_headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['data'].collect { |item| item['id'] }).to match_array([order_item_1.id.to_s, order_item_2.id.to_s])
      end
    end

    context "when creating order_items" do
      before do
        ManageIQ::API::Common::Request.with_request(default_request) do
          post "/api/v1.0/orders/#{order_3.id}/order_items", :headers => default_headers, :params => params
        end
      end

      it "creates an order item under an order" do
        expect(json["order_id"]).to eq(order_3.id.to_s)
        expect(json["service_parameters"]["name"]).to eq("fred")
      end

      it "returns a 200 with JSON content" do
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
      end
    end

    context "when showing order_items" do
      it "show an order_item under an order" do
        get "/api/v1.0/orders/#{order_1.id}/order_items/#{order_item_1.id}", :headers => default_headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
      end

      it "show an order_item" do
        get "/api/v1.0/order_items/#{order_item_1.id}", :headers => default_headers
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "DELETE /order_items/:id" do
    let(:order_item) { order_item_1 }

    before do
      delete "/#{api}/order_items/#{order_item.id}", :headers => default_headers
    end

    it "deletes the record" do
      expect(response).to have_http_status(:ok)
    end

    it "sets the discarded_at column" do
      expect(OrderItem.with_discarded.find_by(:id => order_item.id).discarded_at).to_not be_nil
    end

    it "returns the restore_key in the body" do
      expect(json["restore_key"]).to eq Digest::SHA1.hexdigest(OrderItem.with_discarded.find(order_item.id).discarded_at.to_s)
    end
  end

  describe "POST /order_items/:id/restore" do
    let(:order_item) { order_item_1 }
    let(:restore_key) { Digest::SHA1.hexdigest(order_item.discarded_at.to_s) }
    let(:params) { {:restore_key => restore_key} }

    before do
      order_item.discard
      post "/#{api}/order_items/#{order_item.id}/restore", :headers => default_headers, :params => params
    end

    context "when restoring a progress_message is successful" do
      it "returns a 200" do
        expect(response).to have_http_status :ok
      end

      it "returns the restored record" do
        expect(json["id"]).to eq order_item.id.to_s
      end
    end

    context "when restoring a progress_message with the wrong restore key" do
      let(:restore_key) { "MrMaliciousRestoreKey" }

      it "returns a 403" do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
