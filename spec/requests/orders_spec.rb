describe "OrderRequests", :type => :request do
  around do |example|
    bypass_rbac do
      example.call
    end
  end
  let(:tenant) { create(:tenant) }
  let!(:order) { create(:order, :tenant_id => tenant.id) }
  let!(:order2) { create(:order, :tenant_id => tenant.id) }

  # TODO: Update this context with new logic. Will be fixed with
  # https://projects.engineering.redhat.com/browse/SSP-237
  context "submit order" do
    let(:svc_object) { instance_double("Catalog::CreateApprovalRequest") }
    let(:topo_ex) { Catalog::TopologyError.new("kaboom") }
    let(:params) { order.id.to_s }
    before do
      allow(Catalog::CreateApprovalRequest).to receive(:new).with(params).and_return(svc_object)
    end

    it "v1.0 successfully creates approval requests" do
      allow(svc_object).to receive(:process).and_return(svc_object)
      allow(svc_object).to receive(:order).and_return(order)

      post "#{api}/orders/#{order.id}/submit_order", :headers => default_headers

      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
    end
  end

  context "#cancel_order" do
    let(:cancel_order) { instance_double("Catalog::CancelOrder", :order => "test") }

    before do
      allow(Catalog::CancelOrder).to receive(:new).and_return(cancel_order)
    end

    context "when the order is cancelable" do
      before do
        allow(cancel_order).to receive(:process).and_return(cancel_order)
      end

      it "successfully cancels the order" do
        patch "/api/v1.0/orders/#{order.id}/cancel", :headers => default_headers

        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
      end
    end

    context "when the order is not cancelable" do
      before do
        allow(cancel_order).to receive(:process).and_raise(Catalog::OrderUncancelable.new("Order not cancelable"))
      end

      it "returns a 422" do
        patch "/api/v1.0/orders/#{order.id}/cancel", :headers => default_headers

        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to eq({"error" => "Order not cancelable"}.to_json)
      end
    end
  end

  context "add to order" do
    let(:svc_object) { instance_double("Catalog::AddToOrder") }
    before do
      allow(Catalog::AddToOrder).to receive(:new).and_return(svc_object)
    end

    it "successfully adds to an order" do
      allow(svc_object).to receive(:process).and_return(svc_object)
      allow(svc_object).to receive(:order).and_return(order)

      post "/api/v1.0/orders/#{order.id}/order_items", :headers => default_headers

      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
    end
  end

  context "list orders" do
    context "without filter" do
      before do
        get "/api/v1.0/orders", :headers => default_headers
      end

      it "returns a 200" do
        expect(response.content_type).to eq("application/json")
        expect(response).to have_http_status(:ok)
      end

      it "returns them in reversed order" do
        expect(json['data'][0]['id']).to eq(order2.id.to_s)
        expect(json['data'][1]['id']).to eq(order.id.to_s)
      end
    end

    context "with filter" do
      before do
        get "/api/v1.0/orders?filter[id]=#{order.id}", :headers => default_headers
      end

      it "follows filter parameter" do
        expect(json['data'].first['id']).to eq order.id.to_s
        expect(json['meta']['count']).to eq 1
      end
    end
  end

  context "create" do
    it "create a new order" do
      post "/api/v1.0/orders", :headers => default_headers, :params => {}
      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
    end
  end
end
