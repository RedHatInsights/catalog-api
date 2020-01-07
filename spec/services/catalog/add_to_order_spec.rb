describe Catalog::AddToOrder, :type => :service do
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
                                     'provider_control_parameters' => {'age' => 50})
  end

  let(:invalid_params) do
    ActionController::Parameters.new('order_id'          => order.id,
                                     'portfolio_item_id' => portfolio_item.id,
                                     'count'             => 1)
  end

  let(:subject) { described_class.new(params).process }

  let(:request) { default_request }
  let(:service_plans_instance) { instance_double(Catalog::ServicePlans) }

  before do
    allow(Catalog::ServicePlans).to receive(:new).and_return(service_plans_instance)
    allow(service_plans_instance).to receive(:process).and_return(service_plans_instance)
    allow(service_plans_instance).to receive(:items).and_return([OpenStruct.new(:id => "1")])
  end

  it "add order item" do
    Insights::API::Common::Request.with_request(request) do
      expect(subject.order_item.portfolio_item_id).to eq(portfolio_item.id)
    end
  end

  context "when the parameters are invalid" do
    let(:invalid_params) do
      ActionController::Parameters.new('order_id'          => order.id,
                                       'portfolio_item_id' => portfolio_item.id,
                                       'count'             => 1)
    end

    it "raises an ActiveRecord::RecordInvalid exception and logs a message" do
      expect(Rails.logger).to receive(:error).with(/Error creating order item for order_id #{order_id}/)
      expect { described_class.new(invalid_params).process }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  context "invalid order" do
    let(:order_id) { "999" }
    it "invalid order" do
      expect { described_class.new(params).process }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "when passing in a x-rh-identity header" do
    it 'sets the context to the encoded_user_hash' do
      Insights::API::Common::Request.with_request(request) do
        expect(subject.order_item.context["headers"]["x-rh-identity"]).to eq encoded_user_hash
      end
    end

    it 'can recreate the request from the context' do
      item = nil
      Insights::API::Common::Request.with_request(request) do
        item = subject.order_item
      end

      new_request = item.context.transform_keys(&:to_sym)
      Insights::API::Common::Request.with_request(new_request) do
        expect(Insights::API::Common::Request.current.user.username).to eq "jdoe"
        expect(Insights::API::Common::Request.current.user.email).to eq "jdoe@acme.com"
      end
    end
  end

  context "service_plan_ref_lookup" do
    it "gets the correct service_plan_ref from topology" do
      Insights::API::Common::Request.with_request(request) do
        expect(subject.order_item.service_plan_ref).to eq "1"
      end
    end
  end
end
