describe Internal::V1x0::NotifyController, :type => :request do
  let(:api_version) { "internal/v1.0" }
  around do |example|
    bypass_rbac do
      example.call
    end
  end

  describe "POST /notify/approval_request/:id" do
    let!(:approval_request) { create(:approval_request, :approval_request_ref => "123") }
    let(:approval_transition) { instance_double("Catalog::UpdateOrderItem") }

    before do
      allow(Catalog::ApprovalTransition).to receive(:new).and_return(approval_transition)
      allow(approval_transition).to receive(:process)
    end

    it "returns a 200" do
      post "/#{api_version}/notify/approval_request/123", :headers => default_headers, :params => {:payload => {:decision => "approved", :request_id => "123"}, :message => "request_finished"}
      expect(response.status).to eq(200)
    end
  end

  describe "POST /notify/task/:task_id" do
    let(:determine_task_relevancy) { instance_double("Catalog::DetermineTaskRelevancy") }

    before do
      allow(Catalog::DetermineTaskRelevancy).to receive(:new)
        .with(
          having_attributes(
            :payload => hash_including("status" => "test", "task_id" => "321"),
            :message => "message"
          )
        )
        .and_return(determine_task_relevancy)
      allow(determine_task_relevancy).to receive(:process)
    end

    it "delegates to another service" do
      expect(determine_task_relevancy).to receive(:process)
      post "/#{api_version}/notify/task/321", :headers => default_headers, :params => {:payload => {:status => "test"}, :message => "message"}
    end

    it "returns a 200" do
      post "/#{api_version}/notify/task/321", :headers => default_headers, :params => {:payload => {:status => "test"}, :message => "message"}

      expect(response.status).to eq(200)
    end
  end
end
