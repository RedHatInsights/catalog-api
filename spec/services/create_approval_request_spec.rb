describe CreateApprovalRequest do
  include ServiceSpecHelper

  let(:car) do
    with_modified_env APPROVAL_SERVICE_URL: 'http://www.example.com' do
      CreateApprovalRequest.new(:params => params, :request => request)
    end
  end

  let(:identity) do
    {'identity' => {'is_org_admin' => true, 'username' => 'Freddy Kreuger'} }
  end

  let(:request) do
    ActionDispatch::TestRequest.new({}).tap do |obj|
      obj.headers['x-rh-auth-identity'] = Base64.encode64(identity.to_json)
    end
  end

  let(:oisp) { instance_double("OrderItemSanitizedParameters") }
  let(:api_instance) { double(:api_instance) }

  let(:approval_request) { instance_double("ApprovalAPIClient::Request", :id => "900") }
  let(:approval_workflow_ref) { "998" }
  let(:service_offering_ref) { "999" }
  let(:service_plan_ref) { "777" }
  let(:order) { create(:order) }
  let!(:order_item) do
    create(:order_item, :portfolio_item_id           => portfolio_item.id,
                        :order_id                    => order.id,
                        :service_plan_ref            => service_plan_ref,
                        :service_parameters          => { 'b' => 1 },
                        :provider_control_parameters => { 'a' => 1 },
                        :count                       => 1)
  end
  let(:portfolio_item) do
    create(:portfolio_item, :service_offering_ref  => service_offering_ref,
                            :approval_workflow_ref => approval_workflow_ref)
  end
  let(:portfolio_item_id) { portfolio_item.id.to_s }
  let(:params) do
    ActionController::Parameters.new('order_id' => order.id.to_s)
  end

  before do
    allow(car).to receive(:api_instance).and_return(api_instance)
    allow(OrderItemSanitizedParameters).to receive(:new).and_return(oisp)
    allow(oisp).to receive(:process).and_return('a' => 1)
  end

  context "#process" do
    it "success scenario" do
      allow(api_instance).to receive(:add_request) do |ref, obj|
        expect(ref).to eq(portfolio_item.approval_workflow_ref)
        expect(obj.name).to eq(portfolio_item.name)
      end.and_return(approval_request)

      car.process
    end

    it "failure scenario" do
      allow(api_instance).to receive(:add_request)
        .and_raise(ApprovalAPIClient::ApiError.new("Kaboom"))

      expect { car.process }.to raise_error(StandardError)
    end
  end

  context "missing header" do
    let(:request) { ActionDispatch::TestRequest.new({}) }

    it "raises exception" do
      expect { car.process }.to raise_error(StandardError, /x-rh-auth-identity/)
    end
  end
end
