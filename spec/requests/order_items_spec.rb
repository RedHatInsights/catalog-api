describe "OrderItemsRequests", :type => :request do
  around do |example|
    bypass_rbac do
      example.call
    end
  end

  let(:tenant) { create(:tenant) }
  let!(:order_1) { create(:order, :tenant_id => tenant.id) }
  let!(:order_2) { create(:order, :tenant_id => tenant.id) }
  let!(:order_3) { create(:order, :tenant_id => tenant.id) }
  let!(:order_item_1) { create(:order_item, :order_id => order_1.id, :portfolio_item_id => portfolio_item.id, :tenant_id => tenant.id) }
  let!(:order_item_2) { create(:order_item, :order_id => order_2.id, :portfolio_item_id => portfolio_item.id, :tenant_id => tenant.id) }
  let(:portfolio_item) { create(:portfolio_item, :service_offering_ref => "123", :tenant_id => tenant.id) }
  let(:params) do
    { 'order_id'                    => order_1.id,
      'portfolio_item_id'           => portfolio_item.id,
      'count'                       => 1,
      'service_parameters'          => {'name' => 'fred'},
      'provider_control_parameters' => {'age' => 50},
      'service_plan_ref'            => '10' }
  end

  describe "CRUD" do
    context "when listing order_items" do
      it "lists order items under an order" do
        get "/api/v1.0/orders/#{order_1.id}/order_items", :headers => default_headers

        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['data'].first['id']).to eq(order_item_1.id.to_s)
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

      it "create an order item under an order" do
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
      end

      it "stores the x-rh-insights-id from the headers" do
        get "/api/v1.0/orders/#{order_3.id}/order_items", :headers => default_headers
        expect(json["data"].first["insights_request_id"]).to eq default_headers["x-rh-insights-request-id"]
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

  describe "#approval_requests" do
    let!(:approval) { create(:approval_request, :order_item_id => order_item_1.id, :workflow_ref => "1", :tenant_id => tenant.id) }

    context "list" do
      before do
        get "#{api}/order_items/#{order_item_1.id}/approval_requests", :headers => default_headers
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
