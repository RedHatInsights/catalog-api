describe Catalog::CreateApprovalRequest, :type => :service do
  let(:subject) { described_class.new(task) }
  let(:task) { TopologicalInventoryApiClient::Task.new(:id => "123") }

  around do |example|
    with_modified_env(:APPROVAL_URL => "http://localhost") do
      Insights::API::Common::Request.with_request(default_request) { example.call }
    end
  end

  let(:order) { order_item.order }
  let!(:order_item) { create(:order_item, :topology_task_ref => "123") }

  let(:create_request_body_from) { instance_double(Catalog::CreateRequestBodyFrom, :result => request_body_from) }
  let(:request_body_from) { {"test" => "test"}.to_json }

  before do
    allow(Catalog::CreateRequestBodyFrom).to receive(:new).with(order, order_item, task).and_return(create_request_body_from)
    allow(create_request_body_from).to receive(:process).and_return(create_request_body_from)

    stub_request(:get, "http://localhost/api/approval/v1.0/workflows/1")
      .to_return(:status => 200, :body => "", :headers => {"Content-type" => "application/json"})
  end

  describe "#process" do
    context "when the approval succeeds" do
      before do
        stub_request(:post, "http://localhost/api/approval/v1.0/requests")
          .with(:body => request_body_from)
          .to_return(:status => 200, :body => {:workflow_id => 7, :id => 7, :decision => "approved"}.to_json, :headers => {"Content-type" => "application/json"})
      end

      it "submits the approval request" do
        expect(subject.process.order.state).to eq "Approval Pending"
      end

      it "sets up the approval_request on the order item" do
        item = subject.process.order.order_items.first
        expect(item.approval_requests.count).to eq 1
      end

      it "creates an approval request" do
        expect(ApprovalRequest.count).to eq(0)
        subject.process
        expect(ApprovalRequest.count).to eq(1)
      end

      it "sets up the approval request object to track approval" do
        subject.process
        approval_request = ApprovalRequest.last

        expect(approval_request.state).to eq "approved"
        expect(approval_request.approval_request_ref).to eq "7"
        expect(approval_request.order_item).to eq order_item
        expect(approval_request.tenant).to eq approval_request.order_item.tenant
      end
    end

    context "when the approval fails" do
      before do
        stub_request(:post, "http://localhost/api/approval/v1.0/requests")
          .with(:body => request_body_from)
          .to_return(:status => 401, :body => {}.to_json, :headers => {"Content-type" => "application/json"})
      end

      it "raises an error and does not create an approval request" do
        expect(ApprovalRequest.count).to eq(0)
        expect { subject.process }.to raise_exception(Catalog::ApprovalError)
        expect(ApprovalRequest.count).to eq(0)
      end
    end

    context "when creating the approval request fails" do
      before do
        stub_request(:post, "http://localhost/api/approval/v1.0/requests")
          .with(:body => request_body_from)
          .to_return(:status => 200, :body => {:workflow_id => 7, :id => 7, :decision => "approved"}.to_json, :headers => {"Content-type" => "application/json"})
      end

      it "raises an error" do
        ActsAsTenant.without_tenant do
          expect { subject.process }.to raise_exception(ActiveRecord::RecordInvalid)
        end
      end
    end
  end
end
