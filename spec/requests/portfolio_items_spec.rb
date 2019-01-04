describe "PortfolioItemRequests", :type => :request do
  include ServiceSpecHelper

  let(:service_offering_ref) { "998" }
  let(:order)                { create(:order) }
  let(:portfolio_item)       { create(:portfolio_item, :service_offering_ref => service_offering_ref) }
  let(:svc_object)           { instance_double("ServiceCatalog::ServicePlans") }
  let(:plans)                { [{}, {}] }
  let(:topo_ex)              { ServiceCatalog::TopologyError.new("kaboom") }

  before do
    allow(ServiceCatalog::ServicePlans).to receive(:new).with(portfolio_item.id.to_s).and_return(svc_object)
  end

  it "fetches plans" do
    allow(svc_object).to receive(:process).and_return(svc_object)
    allow(svc_object).to receive(:items).and_return(plans)

    get "/api/v0.0/portfolio_items/#{portfolio_item.id}/service_plans"

    expect(JSON.parse(response.body).count).to eq(2)
    expect(response.content_type).to eq("application/json")
    expect(response).to have_http_status(:ok)
  end

  it "raises error" do
    allow(svc_object).to receive(:process).and_raise(topo_ex)

    get "/api/v0.0/portfolio_items/#{portfolio_item.id}/service_plans"
    expect(response).to have_http_status(:internal_server_error)
  end
end
