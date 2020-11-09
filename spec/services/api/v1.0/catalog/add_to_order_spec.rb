describe Api::V1x0::Catalog::AddToOrder, :type => :service do
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

  let(:subject) { described_class.new(params).process }

  let(:request) { default_request }
  let(:service_plans_instance) { instance_double(Api::V1x0::Catalog::ServicePlans) }
  let(:order_item_sanitized_parameters) { instance_double(Catalog::OrderItemSanitizedParameters, :sanitized_parameters => {"name" => "fred"}) }

  before do
    allow(Api::V1x0::Catalog::ServicePlans).to receive(:new).and_return(service_plans_instance)
    allow(service_plans_instance).to receive(:process).and_return(service_plans_instance)
    allow(service_plans_instance).to receive(:items).and_return([OpenStruct.new(:id => "1")])
    allow(Catalog::OrderItemSanitizedParameters).to receive(:new).with(:order_item => order_item).and_return(order_item_sanitized_parameters)
    allow(order_item_sanitized_parameters).to receive(:process).and_return(order_item_sanitized_parameters)
  end

  it "add order item" do
    Insights::API::Common::Request.with_request(request) do
      expect(subject.order_item.portfolio_item_id).to eq(portfolio_item.id)
      expect(subject.order_item.name).to eq(portfolio_item.name)
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
      item = Insights::API::Common::Request.with_request(request) { subject.order_item }

      new_request = item.context.transform_keys(&:to_sym)
      Insights::API::Common::Request.with_request(new_request) do
        expect(Insights::API::Common::Request.current.user.username).to eq "jdoe"
        expect(Insights::API::Common::Request.current.user.email).to eq "jdoe@acme.com"
      end
    end

    it "should create a process message with the x-rh-insights-request-id" do
      progress_message = Insights::API::Common::Request.with_request(request) { subject.order_item.progress_messages.first }
      expect(progress_message.message).to match('Order item tracking ID (x-rh-insights-request-id): gobbledygook')
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
