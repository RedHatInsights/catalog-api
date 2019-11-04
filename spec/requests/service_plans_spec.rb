describe "ServicePlansRequests", :type => :request do
  let(:service_plan) { create(:service_plan) }
  let(:portfolio_item) { service_plan.portfolio_item }
  let(:service_offering_ref) { portfolio_item.service_offering_ref }
  let!(:portfolio_item_without_service_plan) { create(:portfolio_item, :service_offering_ref => service_offering_ref) }

  around do |example|
    with_modified_env(:TOPOLOGICAL_INVENTORY_URL => "http://localhost", :BYPASS_RBAC => 'true') do
      example.call
    end
  end

  let(:topo_service_plan) do
    TopologicalInventoryApiClient::ServicePlan.new(
      :name               => "The Plan",
      :id                 => "1",
      :description        => "A Service Plan",
      :create_json_schema => {"schema" => {}}
    )
  end
  let(:service_plan_response) { TopologicalInventoryApiClient::ServicePlansCollection.new(:data => [topo_service_plan]) }
  let(:service_offering_response) do
    TopologicalInventoryApiClient::ServiceOffering.new(:extra => {"survey_enabled" => true})
  end

  before do
    stub_request(:get, "http://localhost/api/topological-inventory/v1.0/service_offerings/#{service_offering_ref}")
      .to_return(:status => 200, :body => service_offering_response.to_json, :headers => default_headers)
    stub_request(:get, "http://localhost/api/topological-inventory/v1.0/service_offerings/#{service_offering_ref}/service_plans")
      .to_return(:status => 200, :body => service_plan_response.to_json, :headers => default_headers)
  end

  describe "#index" do
    context "when there are service plans in the db" do
      before do
        post "#{api}/service_plans", :headers => default_headers, :params => {:portfolio_item_id => portfolio_item_without_service_plan.id.to_s}
        get "#{api}/portfolio_items/#{portfolio_item_without_service_plan.id}/service_plans", :headers => default_headers
      end

      it "returns what we have in the db" do
        db_plans = portfolio_item_without_service_plan.service_plans

        expect(db_plans.count).to eq json.count
        expect(db_plans.first.portfolio_item_id).to eq portfolio_item_without_service_plan.id
      end
    end

    context "when there are not service plans in the db" do
      before do
        get "#{api}/portfolio_items/#{portfolio_item_without_service_plan.id}/service_plans", :headers => default_headers
      end

      it "returns the newly created ServicePlan in an array" do
        expect(json.first["create_json_schema"]).to eq topo_service_plan.create_json_schema
      end
    end
  end

  describe "#show" do
    before do
      get "#{api}/service_plans/#{service_plan.id}", :headers => default_headers
    end

    it "returns a 200" do
      expect(response).to have_http_status :ok
    end

    it "returns the specified service_plan" do
      expect(json["id"]).to eq service_plan.id.to_s
      expect(json.keys).to match_array %w[base modified portfolio_item_id id]
    end
  end

  describe "#create" do
    before do
      post "#{api}/service_plans", :headers => default_headers, :params => {:portfolio_item_id => portfolio_item_without_service_plan.id.to_s}
    end

    it "pulls in the service plans" do
      expect(portfolio_item_without_service_plan.service_plans.count).to eq 1
    end

    it "returns the imported service plans" do
      expect(json.first["id"]).to eq portfolio_item_without_service_plan.service_plans.first.id.to_s
    end
  end

  describe "#base" do
    before do
      get "#{api}/service_plans/#{service_plan.id}/base", :headers => default_headers
    end

    it "returns a 200" do
      expect(response).to have_http_status :ok
    end

    it "returns the base schema from the service_plan" do
      expect(json["schema"]).to eq service_plan.base["schema"]
    end
  end
end
