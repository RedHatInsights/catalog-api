describe "PortfolioItemRequests", :type => :request do
  include ServiceSpecHelper

  let(:service_offering_ref) { "998" }
  let(:order)                { create(:order) }
  let(:portfolio_item)       { create(:portfolio_item, :service_offering_ref => service_offering_ref) }
  let(:portfolio_item_id)    { portfolio_item.id }
  let(:svc_object)           { instance_double("ServiceCatalog::ServicePlans") }
  let(:plans)                { [{}, {}] }
  let(:topo_ex)              { ServiceCatalog::TopologyError.new("kaboom") }

  before do
    allow(ServiceCatalog::ServicePlans).to receive(:new).with(portfolio_item.id.to_s).and_return(svc_object)
  end

  describe 'DELETE admin tagged /portfolio_items/:portfolio_item_id' do
    #TODO https://github.com/ManageIQ/service_portal-api/issues/85
    let(:valid_attributes) { { :name => 'PatchPortfolio', :description => 'description for patched portfolio' } }

    context 'when :portfolio_item_id is valid' do
      before do
        delete "/api/v0.0/portfolio_items/#{portfolio_item_id}", :headers => admin_headers, :params => valid_attributes
      end

      it 'deletes the record' do
        expect(response).to have_http_status(204)
      end
    end
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
