require 'spec_helper'

describe ServicePlans do
  let(:service_offering_ref) { "998" }
  let(:portfolio_item) { create(:portfolio_item, :service_offering_ref => service_offering_ref) }
  let(:service_plans) { ServicePlans.new(params) }
  let(:api_instance) { double() }
  let(:params) { {'portfolio_item_id' => portfolio_item.id} }

  it "fetches the array of plans" do
    with_modified_env TOPOLOGY_SERVICE_URL: 'http://www.example.com' do
      Plan = Struct.new(:name, :id, :description, :create_json_schema)
      plan1 = Plan.new("Plan A", "1", "Plan A", {})
      plan2 = Plan.new("Plan B", "2", "Plan B", {})
      allow(service_plans).to receive(:api_instance).and_return(api_instance)
    expect(api_instance).to receive(:list_service_offering_service_plans).with(portfolio_item.service_offering_ref).and_return([plan1, plan2])

      service_plans.process
    end
  end

  context "invalid portfolio item" do
    let(:params) { {'portfolio_item_id' => 1 } }
    it "raises exception" do
      with_modified_env TOPOLOGY_SERVICE_URL: 'http://www.example.com' do
        expect { service_plans.process }.to raise_error(StandardError)
      end
    end
  end

  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end
end
