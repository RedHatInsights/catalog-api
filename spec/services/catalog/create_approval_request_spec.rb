describe Catalog::CreateApprovalRequest, :type => :service do
  let(:create_approval_request) { described_class.new(order.id) }

  around do |example|
    with_modified_env(:APPROVAL_URL => "http://localhost") do
      ManageIQ::API::Common::Request.with_request(default_request) { example.call }
    end
  end

  let!(:order) { order_item.order }
  let!(:portfolio_item) { create(:portfolio_item) }
  let!(:order_item) { create(:order_item, :portfolio_item => portfolio_item) }

  let(:sanitize_service_class) do
    class_double(Catalog::OrderItemSanitizedParameters).as_stubbed_const(:transfer_nested_constants => true)
  end
  let(:sanitize_service_instance) { instance_double(Catalog::OrderItemSanitizedParameters) }
  let(:local_tag_service_instance) { instance_double(Tags::CollectLocalOrderResources, :tag_resources => []) }
  let(:hashy) { { :a => 1 } }

  before do
    allow(sanitize_service_class).to receive(:new).and_return(sanitize_service_instance)
    allow(sanitize_service_instance).to receive(:process).and_return(hashy)

    stub_request(:get, "http://localhost/api/approval/v1.0/workflows/1")
      .to_return(:status => 200, :body => "", :headers => {"Content-type" => "application/json"})
  end

  describe "#process" do
    let(:request) { create_approval_request.process }

    context "when the approval succeeds" do
      before do
        stub_request(:post, "http://localhost/api/approval/v1.0/requests")
          .to_return(:status => 200, :body => {:workflow_id => 7, :id => 7, :decision => "approved"}.to_json, :headers => {"Content-type" => "application/json"})
      end

      it "submits the approval request" do
        expect(request.order.state).to eq "Approval Pending"
      end

      it "sets up the approval_request on the order item" do
        item = request.order.order_items.first
        expect(item.approval_requests.count).to eq 1
      end
    end

    context "when the approval fails" do
      before do
        stub_request(:post, "http://localhost/api/approval/v1.0/requests")
          .to_return(:status => 401, :body => {}.to_json, :headers => {"Content-type" => "application/json"})
      end

      it "raises an error" do
        expect { request }.to raise_exception(Catalog::ApprovalError)
      end
    end
  end

  context "private methods" do
    before do
      stub_request(:post, "http://localhost/api/approval/v1.0/requests")
        .to_return(:status => 200, :body => {:workflow_id => 7, :id => 7, :decision => "approved"}.to_json, :headers => {"Content-type" => "application/json"})
    end

    context "#submit_approval_requests" do
      it "calls out to Approval for every workflow on the order" do
        allow(Tags::CollectLocalOrderResources).to receive(:new).with(:order_id => order.id).and_return(local_tag_service_instance)
        allow(local_tag_service_instance).to receive(:process).and_return(local_tag_service_instance)
        req = ApprovalApiClient::RequestIn.new.tap do |request|
          request.name = order_item.portfolio_item.name
          request.content = {
            :product   => order_item.portfolio_item.name,
            :portfolio => order_item.portfolio_item.portfolio.name,
            :order_id  => order_item.order_id.to_s,
            :params    => hashy
          }
          request.tag_resources = []
        end.to_json

        create_approval_request.send(:submit_approval_requests, order_item)
        expect(a_request(:post, "http://localhost/api/approval/v1.0/requests")
          .with(:body => req)) .to have_been_made
      end
    end

    context "#create_approval_request" do
      let(:request_out) { ApprovalApiClient::Request.new(:workflow_id => "1", :id => 2, :decision => 'undecided') }
      let(:approval_request) { create_approval_request.send(:create_approval_request, request_out, order_item) }

      it "returns an ApprovalRequest Object" do
        expect(approval_request.class.name).to eq "ApprovalRequest"
      end

      it "populates all of the fields from the Response from Approval" do
        resp = approval_request
        expect(resp.workflow_ref).to eql request_out.workflow_id
        expect(resp.approval_request_ref).to eq request_out.id.to_s
        expect(resp.state).to eq request_out.decision
      end
    end

    context "#request_body_from" do
      it "returns a RequestIn Object populated with all of the order_item information" do
        req = create_approval_request.send(:request_body_from, order_item)

        expect(req.name).to eq order_item.portfolio_item.name
        expect(req.content).to include(:product   => order_item.portfolio_item.name,
                                       :portfolio => order_item.portfolio_item.portfolio.name,
                                       :order_id  => order_item.order_id.to_s,
                                       :params    => hashy)
      end
    end
  end
end
