describe "OrderRequests", :type => :request do
  include ServiceSpecHelper

  let(:order) { create(:order) }

  context "submit order" do
    let(:svc_object) { instance_double("ServiceCatalog::SubmitOrder") }
    let(:topo_ex) { ServiceCatalog::TopologyError.new("kaboom") }
    let(:params) { order.id.to_s }
    before do
      allow(ServiceCatalog::SubmitOrder).to receive(:new).with(params).and_return(svc_object)
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
  end

  context "add to order" do
    let(:svc_object) { instance_double("ServiceCatalog::AddToOrder") }
    before do
      allow(ServiceCatalog::AddToOrder).to receive(:new).and_return(svc_object)
    end

    it "successfully adds to an order" do
      allow(svc_object).to receive(:process).and_return(svc_object)
      allow(svc_object).to receive(:order).and_return(order)

      post "/api/v0.0/orders/#{order.id}/items", :headers => admin_headers

      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:ok)
    end
  end
end
