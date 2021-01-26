describe "v1.0 - ServicePlansRequests", :type => [:request, :v1, :inventory] do
  let(:service_plan) { create(:service_plan, :base => JSON.parse(modified_schema)) }
  let(:portfolio_item) { service_plan.portfolio_item }
  let(:service_offering_ref) { portfolio_item.service_offering_ref }
  let!(:portfolio_item_without_service_plan) { create(:portfolio_item, :service_offering_ref => service_offering_ref) }

  let(:modified_schema) { File.read(Rails.root.join("spec", "support", "ddf", "valid_service_plan_ddf.json")) }

  around do |example|
    with_modified_env(:BYPASS_RBAC => 'true') do
      Insights::API::Common::Request.with_request(default_request) { example.call }
    end
  end

  let(:inventory_service_plan) do
    CatalogInventoryApiClient::ServicePlan.new(
      :name               => "The Plan",
      :id                 => "1",
      :description        => "A Service Plan",
      :create_json_schema => JSON.parse(modified_schema)
    )
  end
  let(:service_plan_response) { CatalogInventoryApiClient::ServicePlansCollection.new(:data => [inventory_service_plan]) }
  let(:service_offering_response) do
    CatalogInventoryApiClient::ServiceOffering.new(:extra => {"survey_enabled" => true})
  end

  before do
    stub_request(:get, inventory_url("service_offerings/#{service_offering_ref}"))
      .to_return(:status => 200, :body => service_offering_response.to_json, :headers => default_headers)
    stub_request(:get, inventory_url("service_offerings/#{service_offering_ref}/service_plans"))
      .to_return(:status => 200, :body => service_plan_response.to_json, :headers => default_headers)
  end

  describe "#index" do
    context "when there are service plans in the db" do
      before do
        post "#{api_version}/service_plans", :headers => default_headers, :params => {:portfolio_item_id => portfolio_item_without_service_plan.id.to_s}
      end

      context "when the modified schema is nil" do
        before do
          get "#{api_version}/portfolio_items/#{portfolio_item_without_service_plan.id}/service_plans", :headers => default_headers
        end

        it "returns imported as true" do
          expect(json.first['imported']).to be_truthy
        end

        it "returns the base schema" do
          expect(json.first['create_json_schema']).to eq service_plan.base
        end

        it "shows modified as false" do
          expect(json.first['modified']).to be_falsey
        end
      end

      context "when the modified schema is present" do
        before do
          portfolio_item_without_service_plan.service_plans.first.update(:modified => JSON.parse(modified_schema))
          get "#{api_version}/portfolio_items/#{portfolio_item_without_service_plan.id}/service_plans", :headers => default_headers
        end

        it "returns imported as true" do
          expect(json.first['imported']).to be_truthy
        end

        it "returns the imported schema" do
          expect(json.first['create_json_schema']).to eq JSON.parse(modified_schema)
        end

        it "shows modified as true" do
          expect(json.first['modified']).to be_truthy
        end
      end
    end

    context "when there are not service plans in the db" do
      before do
        get "#{api_version}/portfolio_items/#{portfolio_item_without_service_plan.id}/service_plans", :headers => default_headers
      end

      it "returns the newly created ServicePlan in an array" do
        expect(json.first["create_json_schema"]).to eq inventory_service_plan.create_json_schema
      end

      it "shows imported as false" do
        expect(json.first["imported"]).to be_falsey
      end

      it "shows modified as false" do
        expect(json.first['modified']).to be_falsey
      end
    end
  end

  describe "#show" do
    before do
      get "#{api_version}/service_plans/#{service_plan.id}", :headers => default_headers
    end

    context "when the service plan base is different than inventory's base" do
      let(:service_plan) { create(:service_plan) }

      it "returns a 400" do
        expect(response).to have_http_status(400)
      end
    end

    context "when the service plan has not changed" do
      it "returns a 200" do
        expect(response).to have_http_status :ok
      end

      it "returns the specified service_plan" do
        expect(json["id"]).to eq service_plan.id.to_s
        expect(json.keys).to match_array %w[service_offering_id create_json_schema portfolio_item_id id description name imported modified]
      end
    end
  end

  describe "#create" do
    context "when there is not a service_plan for the portfolio_item specified" do
      subject do
        post "#{api_version}/service_plans", :headers => default_headers, :params => {:portfolio_item_id => portfolio_item_without_service_plan.id.to_s}
      end

      before do |example|
        subject unless example.metadata[:subject_inside]
      end

      it "pulls in the service plans" do
        expect(portfolio_item_without_service_plan.service_plans.count).to eq 1
      end

      it "returns the imported service plans" do
        expect(json.first["id"]).to eq portfolio_item_without_service_plan.service_plans.first.id.to_s
      end

      it "returns the base schema in the :create_json_schema field" do
        expect(json.first["create_json_schema"]).to eq JSON.parse(modified_schema)
      end

      it_behaves_like "action that tests authorization", :create?, ServicePlan
    end

    context "when a service_plan already exists for the portfolio_item specified" do
      before do
        post "#{api_version}/service_plans", :headers => default_headers, :params => {:portfolio_item_id => portfolio_item_without_service_plan.id.to_s}
        post "#{api_version}/service_plans", :headers => default_headers, :params => {:portfolio_item_id => portfolio_item_without_service_plan.id.to_s}
      end

      it "returns a conflict response" do
        expect(response).to have_http_status(409)
      end
    end
  end

  describe "#base" do
    context "when the service plan exists" do
      before do
        get "#{api_version}/service_plans/#{service_plan.id}/base", :headers => default_headers
      end

      it "returns a 200" do
        expect(response).to have_http_status :ok
      end

      it "returns the base schema from the service_plan" do
        expect(json["create_json_schema"]["schema"]).to eq service_plan.base["schema"]
      end
    end

    context "when the service plan does not exist" do
      it "returns a 404" do
        service_plan.destroy
        get "#{api_version}/service_plans/#{service_plan.id}/base", :headers => default_headers

        expect(response).to have_http_status :not_found
      end
    end
  end

  describe "#modified" do
    context "when there is a modified schema" do
      before do
        get "#{api_version}/service_plans/#{service_plan.id}/modified", :headers => default_headers
      end

      it "returns a 200" do
        expect(response).to have_http_status :ok
      end

      it "returns the modified schema from the service_plan" do
        expect(json["create_json_schema"]["schema"]).to eq service_plan.modified["schema"]
        expect(json["create_json_schema"]["schema"]).not_to eq service_plan.base["schema"]
      end

      it "shows imported as true" do
        expect(json["imported"]).to be_truthy
      end
    end

    context "when there is not a modified schema" do
      before do
        service_plan.update!(:modified => nil)
      end

      it "returns a 204" do
        get "#{api_version}/service_plans/#{service_plan.id}/modified", :headers => default_headers

        expect(response).to have_http_status :no_content
      end
    end

    context "when the service plan does not exist" do
      it "returns a 404" do
        service_plan.destroy
        get "#{api_version}/service_plans/#{service_plan.id}/modified", :headers => default_headers

        expect(response).to have_http_status :not_found
      end
    end
  end

  describe "#update_modified" do
    subject do
      patch "#{api_version}/service_plans/#{service_plan.id}/modified", :headers => default_headers, :params => params
    end

    before do |example|
      subject unless example.metadata[:subject_inside]
    end

    context "when patching the modified schema with a valid schema" do
      let(:params) { {:modified => JSON.parse(modified_schema)} }

      it "returns a 200" do
        expect(response).to have_http_status :ok
      end

      it "returns the newly modified schema from the service_plan" do
        expect(json).to eq params[:modified]
      end

      it_behaves_like "action that tests authorization", :update_modified?, ServicePlan
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

      it_behaves_like "action that tests authorization", :update_modified?, ServicePlan
    end
  end

  describe "#reset" do
    subject { post "#{api_version}/service_plans/#{service_plan.id}/reset", :headers => default_headers }

    context "when there is a modified schema" do
      before do |example|
        subject unless example.metadata[:subject_inside]
      end

      it "returns a 200" do
        expect(response).to have_http_status :ok
      end

      it_behaves_like "action that tests authorization", :reset?, ServicePlan
    end

    context "when there is not a modified schema" do
      before do |example|
        service_plan.update!(:modified => nil)

        subject unless example.metadata[:subject_inside]
      end

      it "returns a 204" do
        expect(response).to have_http_status :no_content
      end

      it_behaves_like "action that tests authorization", :reset?, ServicePlan
    end
  end
end
