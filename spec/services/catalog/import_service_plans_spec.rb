describe Catalog::ImportServicePlans, :type => [:service, :topology, :current_forwardable] do
  let(:service_offering_ref) { "1" }
  let(:portfolio_item) { create(:portfolio_item, :service_offering_ref => service_offering_ref) }
  let(:subject) { described_class.new(portfolio_item.id) }
  let(:service_plan) do
    TopologicalInventoryApiClient::ServicePlan.new(
      :name               => "The Plan",
      :id                 => "1",
      :description        => "A Service Plan",
      :create_json_schema => {"schema" => {}}
    )
  end
  let(:service_plan_response) { TopologicalInventoryApiClient::ServicePlansCollection.new(:data => data) }
  let(:service_offering_response) do
    TopologicalInventoryApiClient::ServiceOffering.new(:extra => {"survey_enabled" => true})
  end

  before do
    stub_request(:get, topological_url("service_offerings/1"))
      .to_return(:status => 200, :body => service_offering_response.to_json, :headers => default_headers)
    stub_request(:get, topological_url("service_offerings/1/service_plans"))
      .to_return(:status => 200, :body => service_plan_response.to_json, :headers => default_headers)
  end

  describe "#process" do
    shared_examples_for "returns_json" do
      it "returns the json" do
        schemas = subject.json.collect { |plan| plan["create_json_schema"] }
        expect(schemas.all? { |schema| schema == service_plan.create_json_schema }).to be_truthy
      end
    end

    context "when force_reset is set" do
      let!(:service_plan_current) { create(:service_plan, :portfolio_item => portfolio_item) }
      let(:data) { [service_plan] }

      before do
        described_class.new(portfolio_item.id, true).process
      end

      it "destroys the current service_plans" do
        expect{ServicePlan.find(service_plan_current.id)}.to raise_exception(ActiveRecord::RecordNotFound)
      end

      it "reimports the service plan" do
        portfolio_item.service_plans.reload
        expect(portfolio_item.service_plans.any?).to be_truthy
      end
    end

    context "when there is one plan" do
      let(:data) { [service_plan] }

      before do
        subject.process
      end

      it "reaches out to topology twice" do
        expect(a_request(:get, /topological-inventory\/v2.0\/service_offerings/)).to have_been_made.twice
      end

      it "adds the ServicePlan to the portfolio_item" do
        expect(portfolio_item.service_plans.count).to eq 1
      end

      it_behaves_like "returns_json"
    end

    context "when there are multiple plans" do
      let(:data) { [service_plan, service_plan.dup] }

      before do
        subject.process
      end

      it "reaches out to topology twice" do
        expect(a_request(:get, /topological-inventory\/v2.0\/service_offerings/)).to have_been_made.twice
      end

      it "adds both the ServicePlans to the portfolio_item" do
        expect(portfolio_item.service_plans.count).to eq 2
      end

      it_behaves_like "returns_json"
    end
  end
end
