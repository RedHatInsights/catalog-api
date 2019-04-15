describe Catalog::AddToOrder do
  let(:service_offering_ref) { "998" }
  let(:order) { create(:order) }
  let(:order_id) { order.id.to_s }
  let(:order_item) { create(:order_item, :portfolio_item_id => portfolio_item.id) }
  let(:portfolio_item) { create(:portfolio_item, :service_offering_ref => service_offering_ref, :owner => 'wilma') }
  let(:portfolio_item_id) { portfolio_item.id.to_s }

  let(:params) do
    ActionController::Parameters.new('order_id'                    => order_id,
                                     'portfolio_item_id'           => portfolio_item_id,
                                     'count'                       => 1,
                                     'service_parameters'          => {'name' => 'fred'},
                                     'provider_control_parameters' => {'age' => 50},
                                     'service_plan_ref'            => '10')
  end

  let(:invalid_params) do
    ActionController::Parameters.new('order_id'          => order.id,
                                     'portfolio_item_id' => portfolio_item.id,
                                     'count'             => 1)
  end

  let(:order_item) { described_class.new(params).process.order.order_items.first }

  let(:request) { default_request }

  it "add order item" do
    ManageIQ::API::Common::Request.with_request(request) do
      expect(order_item.portfolio_item_id).to eq(portfolio_item.id)
    end
  end

  it "invalid parameters" do
    expect { described_class.new(invalid_params).process }.to raise_error(ActiveRecord::RecordInvalid)
  end

  context "invalid order" do
    let(:order_id) { "999" }
    it "invalid order" do
      expect { described_class.new(params).process }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "when passing in a x-rh-identity header" do
    it 'sets the context to the encoded_user_hash' do
      ManageIQ::API::Common::Request.with_request(request) do
        expect(order_item.context["headers"]["x-rh-identity"]).to eq encoded_user_hash
      end
    end

    it 'can recreate the request from the context' do
      item = nil
      ManageIQ::API::Common::Request.with_request(request) do
        item = order_item
      end

      new_request = item.context.transform_keys(&:to_sym)
      ManageIQ::API::Common::Request.with_request(new_request) do
        expect(ManageIQ::API::Common::Request.current.user.username).to eq "jdoe"
        expect(ManageIQ::API::Common::Request.current.user.email).to eq "jdoe@acme.com"
      end
    end
  end
end
