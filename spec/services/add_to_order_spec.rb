require 'spec_helper'

describe AddToOrder do
  let(:service_offering_ref) { "998" }
  let(:order) { create(:order) }
  let(:order_id) { order.id.to_s }
  let(:order_item) { create(:order_item, :portfolio_item_id => portfolio_item.id) }
  let(:portfolio_item) { create(:portfolio_item, :service_offering_ref => service_offering_ref) }
  let(:portfolio_item_id) { portfolio_item.id.to_s }

  let(:params) do
    ActionController::Parameters.new('order_id' => order_id,
     'portfolio_item_id'  =>  portfolio_item_id,
     'count' => 1,
     'service_parameters' =>  {'name' => 'fred'},
     'provider_control_parameters' => {'age' => 50},
     'service_plan_id' =>   "10")
  end

  let(:invalid_params) do
    ActionController::Parameters.new('order_id' => order.id,
     'portfolio_item_id'  =>  portfolio_item.id,
     'count' => 1)
  end

  it "add order item" do
      AddToOrder.new(params).process
      expect(order.order_items.first.portfolio_item_id).to eq(portfolio_item.id.to_s)
  end

  it "invalid parameters" do
    expect { AddToOrder.new(invalid_params).process }.to raise_error(ActiveRecord::RecordInvalid)
  end

  context "invalid order" do
    let(:order_id) { "999" }
    it "invalid order" do
      expect { AddToOrder.new(params).process }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
