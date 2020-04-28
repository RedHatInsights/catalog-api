describe Internal::V1x0::NotifyController, :type => [:request, :v1_internal] do
  describe "POST /notify/approval_request/:id" do
    let!(:approval_request) { create(:approval_request, :approval_request_ref => "123") }
    let(:approval_transition) { instance_double("Catalog::UpdateOrderItem") }

    before do
      allow(Api::V1x0::Catalog::ApprovalTransition).to receive(:new).and_return(approval_transition)
      allow(approval_transition).to receive(:process)
    end

    it "returns a 200" do
      post "#{api_version}/notify/approval_request/123", :headers => default_headers, :params => {:payload => {:decision => "approved", :request_id => "123"}, :message => "request_finished"}
      expect(response.status).to eq(200)
    end
  end

  describe "POST /notify/task/:task_id" do
    let(:determine_task_relevancy) { instance_double("Catalog::DetermineTaskRelevancy") }

    before do
      allow(Api::V1x0::Catalog::DetermineTaskRelevancy).to receive(:new)
        .with(
          having_attributes(
            :payload => hash_including("status" => "test", "task_id" => "321"),
            :message => "message"
          )
        )
        .and_return(determine_task_relevancy)
      allow(determine_task_relevancy).to receive(:process)
    end

    it "converts the payload into a hash" do
      RSpec::Matchers.define :not_a_parameter do
        match { |actual| actual.class != ActionController::Parameters }
      end

      expect(Api::V1x0::Catalog::DetermineTaskRelevancy).to receive(:new).with(having_attributes(:payload => not_a_parameter))
      post "#{api_version}/notify/task/321", :headers => default_headers, :params => {:payload => {:status => "test"}, :message => "message"}
    end

    it "delegates to another service" do
      expect(determine_task_relevancy).to receive(:process)
      post "#{api_version}/notify/task/321", :headers => default_headers, :params => {:payload => {:status => "test"}, :message => "message"}
    end

    it "returns a 200" do
      post "#{api_version}/notify/task/321", :headers => default_headers, :params => {:payload => {:status => "test"}, :message => "message"}

      expect(response.status).to eq(200)
    end
  end
end
