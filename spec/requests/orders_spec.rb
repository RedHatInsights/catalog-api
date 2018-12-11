describe "OrderRequests", :type => :request do
  include ServiceSpecHelper

  let(:order) { create(:order) }
  let(:svc_object) { instance_double("ServiceCatalog::SubmitOrder") }
  let(:topo_ex) { TopologicalInventoryApiClient::ApiError.new("kaboom") }
  let(:params) { order.id.to_s }
  let(:x_rh_auth_identity) { Base64.encode64({'identity' => {'is_org_admin' => true }}.to_json) }
  let(:headers) { { 'x-rh-auth-identity' => x_rh_auth_identity } }

  before do
    allow(ServiceCatalog::SubmitOrder).to receive(:new).with(params).and_return(svc_object)
  end

  it "submit order" do
    allow(svc_object).to receive(:process).and_return(svc_object)
    allow(svc_object).to receive(:order).and_return(order)

    post "/api/v0.0/orders/#{order.id}", :headers => headers

    expect(response.content_type).to eq("application/json")
    expect(response).to have_http_status(:ok)
  end

  it "raises error" do
    allow(svc_object).to receive(:process).and_raise(topo_ex)

    post "/api/v0.0/orders/#{order.id}", :headers => headers
    expect(response).to have_http_status(:internal_server_error)
  end
end
