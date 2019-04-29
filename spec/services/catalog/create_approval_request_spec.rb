describe Catalog::CreateApprovalRequest do
  let(:create_approval_request) { described_class.new(order.id) }

  let(:tenant) { create(:tenant) }
  let(:workflow_ref) { "1" }
  let!(:order) { create(:order, :tenant_id => tenant.id) }
  let!(:portfolio) { create(:portfolio, :tenant_id => tenant.id) }
  let!(:portfolio_item) { create(:portfolio_item, :portfolio_id => portfolio.id, :workflow_ref => workflow_ref, :tenant_id => tenant.id) }
  let!(:order_item) { create(:order_item, :order_id => order.id, :portfolio_item_id => portfolio_item.id, :tenant_id => tenant.id) }

  let(:approval) { class_double(Approval).as_stubbed_const(:transfer_nested_constants => true) }
  let(:api_instance) { instance_double(ApprovalApiClient::RequestApi) }
  let(:approval_response) { ApprovalApiClient::RequestOut.new(:id => 1, :decision => "undecided", :workflow_id => workflow_ref) }

  let(:sanitize_service_class) do
    class_double(Catalog::OrderItemSanitizedParameters).as_stubbed_const(:transfer_nested_constants => true)
  end
  let(:sanitize_service_instance) { instance_double(Catalog::OrderItemSanitizedParameters) }
  let(:hashy) { { :a => 1 } }
  let(:approval_error) { Catalog::ApprovalError.new("kaboom") }

  before do
    allow(sanitize_service_class).to receive(:new).and_return(sanitize_service_instance)
    allow(sanitize_service_instance).to receive(:process).and_return(hashy)
  end

  describe "#process" do
    let(:request) { create_approval_request.process }

    context "when the approval succeeds" do
      before do
        allow(approval).to receive(:call).and_yield(api_instance)
        allow(api_instance).to receive(:create_request).and_return(approval_response)
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
        allow(approval).to receive(:call).and_raise(approval_error)
      end

      it "raises an error" do
        expect { request }.to raise_exception(Catalog::ApprovalError)
      end
    end
  end

  context "private methods" do
    before do
      allow(approval).to receive(:call).and_yield(api_instance)
      allow(api_instance).to receive(:create_request).and_return(approval_response)
    end

    context "#submit_approval_requests" do
      it "calls out to Approval for every workflow on the order" do
        expect(approval).to receive(:call).once
        create_approval_request.send(:submit_approval_requests, order_item)
      end
    end

    context "#create_approval_request" do
      let(:request_out) { ApprovalApiClient::RequestOut.new(:workflow_id => "1", :id => 2) }
      let(:approval_request) { create_approval_request.send(:create_approval_request, request_out) }

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

    context "#workflows" do
      it "returns the workflow from portfolio_item" do
        workflows = create_approval_request.send(:workflows, portfolio_item)
        expect(workflows.first).to eq portfolio_item.workflow_ref
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
