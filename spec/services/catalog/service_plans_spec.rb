describe Catalog::ServicePlans, :type => :service do
  let(:service_offering_ref) { "998" }
  let(:portfolio_item) { create(:portfolio_item, :service_offering_ref => service_offering_ref) }
  let(:params) { portfolio_item.id }
  let(:service_plans) { described_class.new(params) }

  before do
    allow(Insights::API::Common::Request).to receive(:current_forwardable).and_return(default_headers)
  end

  around do |example|
    with_modified_env(:TOPOLOGICAL_INVENTORY_URL => "http://localhost") do
      example.call
    end
  end

  describe "#process" do
    let(:service_plan_response) { TopologicalInventoryApiClient::ServicePlansCollection.new(:data => data) }
    let(:service_offering_response) do
      TopologicalInventoryApiClient::ServiceOffering.new(:extra => {"survey_enabled" => survey_enabled})
    end

    before do
      stub_request(:get, "http://localhost/api/topological-inventory/v1.0/service_offerings/998")
        .to_return(:status => 200, :body => service_offering_response.to_json, :headers => default_headers)
      stub_request(:get, "http://localhost/api/topological-inventory/v1.0/service_offerings/998/service_plans")
        .to_return(:status => 200, :body => service_plan_response.to_json, :headers => default_headers)
    end

    shared_examples_for "#process when no service plan exists" do
      it "returns an array with one object" do
        expect(items.count).to eq(1)
      end

      it "returns an array with one object with an ID of 'null'" do
        expect(items.first["id"]).to be_nil
      end

      it "returns an array with one object with a service_offering_id" do
        expect(items.first["service_offering_id"]).to eq("998")
      end

      it "returns an array with one object with a specific plain text create json schema" do
        json_schema = items.first["create_json_schema"]
        expect(json_schema["schemaType"]).to eq("default")
        expect(json_schema["schema"]["fields"].first["component"]).to eq("plain-text")
        expect(json_schema["schema"]["fields"].first["name"]).to eq("empty-service-plan")
        expect(json_schema["schema"]["fields"].first["label"]).to match("requires no user input")
      end

      it "returns an array with one object without a name" do
        expect(items.first["name"]).to be_nil
      end

      it "returns an array with one object without a description" do
        expect(items.first["description"]).to be_nil
      end
    end

    context "when there are service plans based on the service offering" do
      let(:items) { service_plans.process.items }
      let(:plan1) do
        TopologicalInventoryApiClient::ServicePlan.new(
          :name               => "Plan A",
          :id                 => "1",
          :description        => "Plan A",
          :create_json_schema => {}
        )
      end
      let(:plan2) do
        TopologicalInventoryApiClient::ServicePlan.new(
          :name               => "Plan B",
          :id                 => "2",
          :description        => "Plan B",
          :create_json_schema => {"schema" => {}}
        )
      end
      let(:data) { [plan1, plan2] }

      context "when the survey is enabled" do
        let(:survey_enabled) { true }

        it "returns an array with two objects" do
          expect(items.count).to eq(2)
        end

        it "returns an array with the first object with an ID of '1'" do
          expect(items.first["id"]).to eq("1")
        end

        it "returns an array with the first object with a service_offering_id" do
          expect(items.first["service_offering_id"]).to eq("998")
        end

        it "returns an array with the first object with a create json schema" do
          expect(items.first["create_json_schema"]).to eq({})
        end

        it "returns an array with the first object with its name" do
          expect(items.first["name"]).to eq("Plan A")
        end

        it "returns an array with the first object with its description" do
          expect(items.first["description"]).to eq("Plan A")
        end
      end

      context "when the survey is disabled" do
        let(:survey_enabled) { false }

        it_behaves_like "#process when no service plan exists"
      end
    end

    context "when there are no service plans based on the service offering" do
      let(:data) { [] }
      let(:items) { service_plans.process.items }

      context "when the survey is enabled" do
        let(:survey_enabled) { true }

        it_behaves_like "#process when no service plan exists"
      end

      context "when the survey is disabled" do
        let(:survey_enabled) { false }

        it_behaves_like "#process when no service plan exists"
      end
    end

    context "invalid portfolio item" do
      let(:params) { 1 }
      let(:data) { [] }
      let(:survey_enabled) { "doesn't matter" }

      it "raises exception" do
        expect { service_plans.process }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
