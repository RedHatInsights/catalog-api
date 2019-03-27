describe "OrderRequests", :type => :request do
  around do |example|
    bypass_tenancy do
      example.call
    end
  end

  let!(:order) { create(:order) }

  # TODO: Update this context with new logic. Will be fixed with
  # https://projects.engineering.redhat.com/browse/SSP-237
  context "submit order" do
    let(:svc_object) { instance_double("Catalog::CreateApprovalRequest") }
    let(:topo_ex) { Catalog::TopologyError.new("kaboom") }
    let(:params) { order.id.to_s }
    before do
      allow(Catalog::CreateApprovalRequest).to receive(:new).with(params).and_return(svc_object)
    end

    it "successfully creates approval requests" do
      allow(svc_object).to receive(:process).and_return(svc_object)
      allow(svc_object).to receive(:order).and_return(order)

      post "/api/v0.0/orders/#{order.id}", :headers => admin_headers

      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
    end

    it "v0.1 successfully creates approval requests" do
      allow(svc_object).to receive(:process).and_return(svc_object)
      allow(svc_object).to receive(:order).and_return(order)

      post "#{api('0.1')}/orders/#{order.id}/submit_order", :headers => admin_headers

      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
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
