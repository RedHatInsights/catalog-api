describe "ServicePlansRequests", :type => :request do
  let(:service_plan) { create(:service_plan, :base => JSON.parse(modified_schema)) }
  let(:portfolio_item) { service_plan.portfolio_item }
  let(:service_offering_ref) { portfolio_item.service_offering_ref }
  let!(:portfolio_item_without_service_plan) { create(:portfolio_item, :service_offering_ref => service_offering_ref) }

  let(:modified_schema) { File.read(Rails.root.join("spec", "support", "ddf", "valid_service_plan_ddf.json")) }

  around do |example|
    with_modified_env(:TOPOLOGICAL_INVENTORY_URL => "http://localhost", :BYPASS_RBAC => 'true') do
      Insights::API::Common::Request.with_request(default_request) { example.call }
    end
  end

  let(:topo_service_plan) do
    TopologicalInventoryApiClient::ServicePlan.new(
      :name               => "The Plan",
      :id                 => "1",
      :description        => "A Service Plan",
      :create_json_schema => JSON.parse(modified_schema)
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
      expect(json.keys).to match_array %w[service_offering_id create_json_schema portfolio_item_id id description name]
    end
  end

  describe "#create" do
    context "when there is not a service_plan for the portfolio_item specified" do
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

    context "when a service_plan already exists for the portfolio_item specified" do
      before do
        post "#{api}/service_plans", :headers => default_headers, :params => {:portfolio_item_id => portfolio_item_without_service_plan.id.to_s}
        post "#{api}/service_plans", :headers => default_headers, :params => {:portfolio_item_id => portfolio_item_without_service_plan.id.to_s}
      end

      it "returns a conflict response" do
        expect(response).to have_http_status(409)
      end
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
      expect(json["create_json_schema"]["schema"]).to eq service_plan.base["schema"]
    end
  end

  describe "#modified" do
    context "when there is a modified schema" do
      before do
        get "#{api}/service_plans/#{service_plan.id}/modified", :headers => default_headers
      end

      it "returns a 200" do
        expect(response).to have_http_status :ok
      end

      it "returns the modified schema from the service_plan" do
        expect(json["create_json_schema"]["schema"]).to eq service_plan.modified["schema"]
        expect(json["create_json_schema"]["schema"]).not_to eq service_plan.base["schema"]
      end
    end

    context "when there is not a modified schema" do
      before do
        service_plan.update!(:modified => nil)
      end

      it "returns a 204" do
        get "#{api}/service_plans/#{service_plan.id}/modified", :headers => default_headers

        expect(response).to have_http_status :no_content
      end
    end
  end

  describe "#update_modified" do
    before do
      patch "#{api}/service_plans/#{service_plan.id}/modified", :headers => default_headers, :params => params
    end

    context "when patching the modified schema with a valid schema" do
      let(:params) { {:modified => JSON.parse(modified_schema)} }

      it "returns a 200" do
        expect(response).to have_http_status :ok
      end

      it "returns the newly modified schema from the service_plan" do
        expect(json).to eq params[:modified]
      end
    end

    context "when patching in a bad schema" do
      let(:params) do
        {
          :modified => JSON.parse(modified_schema).tap do |schema|
                         schema["schema"]["fields"].first["dataType"] = "not-a-real-dataType"
                       end
        }
      end

      it "returns a 400" do
        expect(response).to have_http_status :bad_request
      end

      it "fails validation" do
        expect(first_error_detail).to match(/Catalog::InvalidSurvey/)
      end
    end
  end

  describe "#reset" do
    context "when there is a modified schema" do
      before do
        post "#{api}/service_plans/#{service_plan.id}/reset", :headers => default_headers
      end

      it "returns a 200" do
        expect(response).to have_http_status :ok
      end
    end

    context "when there is not a modified schema" do
      before do
        service_plan.update!(:modified => nil)
      end

      it "returns a 204" do
        post "#{api}/service_plans/#{service_plan.id}/reset", :headers => default_headers

        expect(response).to have_http_status :no_content
      end
    end
  end
end
