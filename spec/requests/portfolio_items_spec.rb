describe "PortfolioItemRequests", :type => :request do
  include ServiceSpecHelper

  let(:service_offering_ref)    { "998" }
  let(:order)                   { create(:order) }
  let(:portfolio_item)          { create(:portfolio_item, :service_offering_ref => service_offering_ref) }
  let(:svc_object)              { instance_double("ServiceCatalog::ServicePlans") }
  let(:plans)                   { [{}, {}] }
  let(:topo_ex)                 { ServiceCatalog::TopologyError.new("kaboom") }

  before do
    allow(ServiceCatalog::ServicePlans).to receive(:new).with(portfolio_item.id.to_s).and_return(svc_object)
  end

  %w(admin user).each do |tag|
    describe "GET #{tag} tagged /portfolio_items" do
      before do
        get "#{api}/portfolio_items", headers: send("#{tag}_headers")
      end

      context 'when portfolios exist' do
        it 'returns status code 200' do
          expect(response).to have_http_status(200)
        end

         it 'returns all portfolio requests' do
          expect(json.size).to eq(1)
        end
      end
    end
  end

  describe 'admin tagged /portfolio_items', :type => :routing  do
    let(:valid_attributes) { { name: 'rspec 1', description: 'rspec 1 description' } }
    context 'with wrong header' do
      it 'returns a 404' do
        pending("Will work again when headers are checked")
        expect(:post => "#{api}/portfolio_items").not_to be_routable
      end
    end
  end

  describe 'POST admin tagged /portfolio_items' do let(:valid_attributes) { { name: 'rh-mediawiki-apb', description: 'Mediawiki apb implementation', service_offering_ref: '21' } }
    context 'when portfolio attributes are valid' do
      before do
        post "#{api}/portfolio_items", params: valid_attributes, headers: admin_headers
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns the new portfolio' do
        expect(json['name']).to eq valid_attributes[:name]
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
