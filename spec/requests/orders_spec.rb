describe "OrderRequests", :type => :request do
  before { disable_tenancy }

  let!(:order) { create(:order) }

  context "submit order" do
    let(:svc_object) { instance_double("Catalog::SubmitOrder") }
    let(:topo_ex) { Catalog::TopologyError.new("kaboom") }
    let(:params) { order.id.to_s }
    before do
      allow(Catalog::SubmitOrder).to receive(:new).with(params).and_return(svc_object)
    end

    it "successfully adds submits an order" do
      allow(svc_object).to receive(:process).and_return(svc_object)
      allow(svc_object).to receive(:order).and_return(order)

      post "/api/v0.0/orders/#{order.id}", :headers => admin_headers

      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
    end

    it "raises error" do
      allow(svc_object).to receive(:process).and_raise(topo_ex)

      post "/api/v0.0/orders/#{order.id}", :headers => admin_headers
      expect(response).to have_http_status(:internal_server_error)
    end

    it "v0.1 successfully adds submits an order" do
      allow(svc_object).to receive(:process).and_return(svc_object)
      allow(svc_object).to receive(:order).and_return(order)

      post "#{api('0.1')}/orders/#{order.id}/submit_order", :headers => admin_headers

      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
    end

    it "v0.1 raises error" do
      allow(svc_object).to receive(:process).and_raise(topo_ex)

      post "#{api('0.1')}/orders/#{order.id}/submit_order", :headers => admin_headers
      expect(response).to have_http_status(:internal_server_error)
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

      post "/api/v0.0/orders/#{order.id}/items", :headers => admin_headers

      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
    end
  end

  context "list orders" do
    it "lists orders v0.0" do
      get "/api/v0.0/orders"

      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).first['id']).to eq(order.id.to_s)
    end

    it "lists orders v0.1" do
      get "/api/v0.1/orders"

      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
      result = JSON.parse(response.body)
      expect(result.keys).to match_array(%w(links meta data))
      expect(result['data'].first['id']).to eq(order.id.to_s)
    end
  end
end
