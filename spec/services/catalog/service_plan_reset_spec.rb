describe Catalog::ServicePlanReset, :type => [:current_forwardable, :topology] do
  let(:subject) { described_class.new(service_plan.id) }
  let(:service_plan_orig) do
    TopologicalInventoryApiClient::ServicePlan.new(
      :name               => "The Plan",
      :id                 => "1",
      :description        => "A Service Plan",
      :create_json_schema => { :schema => {} }
    )
  end
  let(:service_plan_response) { TopologicalInventoryApiClient::ServicePlansCollection.new(:data => data) }
  let(:service_offering_response) do
    TopologicalInventoryApiClient::ServiceOffering.new(:extra => {"survey_enabled" => true})
  end

  before do
    stub_request(:get, topological_url("service_offerings/#{service_plan.portfolio_item.service_offering_ref}"))
      .to_return(:status => 200, :body => service_offering_response.to_json, :headers => default_headers)
    stub_request(:get, topological_url("service_offerings/#{service_plan.portfolio_item.service_offering_ref}/service_plans"))
      .to_return(:status => 200, :body => service_plan_response.to_json, :headers => default_headers)
  end

  describe "#process" do
    let(:data) { [service_plan_orig] }
    let!(:portfolio_item) { service_plan.portfolio_item }
    let!(:service_plan_id) { service_plan.id }
    let!(:service_plan) { create(:service_plan, :modified => modified) }

    context "when the modified attribute is nil" do
      let(:modified) { nil }

      it "sets the status to a 204" do
        expect(subject.process.status).to eq(:no_content)
      end
    end

    context "when the modified attribute is not nil" do
      let(:modified) { "modified" }

      it "updates the plan to have a nil modified attribute" do
        subject.process
        expect(portfolio_item.service_plans.map(&:id)).not_to include(service_plan_id)
      end

      it "sets the status to a 200" do
        expect(subject.process.status).to eq(:ok)
      end
    end

    context "exception handling" do
      let(:modified) { "modified" }
      it "raises StandardError" do
        stub_request(:get, topological_url("service_offerings/#{service_plan.portfolio_item.service_offering_ref}"))
          .to_raise(StandardError)
        expect(Rails.logger).to receive(:error).twice
        expect { subject.process }.to raise_exception(StandardError)
      end
    end
  end
end
