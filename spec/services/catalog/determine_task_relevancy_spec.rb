describe Catalog::DetermineTaskRelevancy, :type => :service do
  let(:subject) { described_class.new(topic) }
  let(:topic) { OpenStruct.new(:payload => {"task_id" => "123"}, :message => "message") }

  around do |example|
    with_modified_env(:TOPOLOGICAL_INVENTORY_URL => "http://topology/") do
      example.call
    end
  end

  before do
    allow(Insights::API::Common::Request).to receive(:current_forwardable).and_return(default_headers)
  end

  describe "#process" do
    before do
      stub_request(:get, "http://topology/api/topological-inventory/v1.0/tasks/123").to_return(
        :status => 200, :body => task.to_json, :headers => default_headers
      )
    end

    context "when the task context has a key path of [:service_instance][:id]" do
      let(:task) { TopologicalInventoryApiClient::Task.new(:context => {:service_instance => {:id => "321"}}) }
      let(:update_order_item) { instance_double("Catalog::UpdateOrderItem") }

      before do
        allow(Catalog::UpdateOrderItem).to receive(:new).with(topic, task).and_return(update_order_item)
      end

      it "delegates to updating the order item" do
        expect(update_order_item).to receive(:process)
        subject.process
      end
    end

    context "when the task context has a key path of [:applied_inventories]" do
      let(:task) { TopologicalInventoryApiClient::Task.new(:context => {:applied_inventories => ["1", "2"]}) }
      let(:create_approval_request) { instance_double("Catalog::CreateApprovalRequest") }

      before do
        allow(Catalog::CreateApprovalRequest).to receive(:new).with(task: task).and_return(create_approval_request)
      end

      it "delegates to creating the approval request" do
        expect(create_approval_request).to receive(:process)
        subject.process
      end
    end

    context "when the task context does not have either key path" do
      let(:task) do
        TopologicalInventoryApiClient::Task.new(
          :state   => "Completed",
          :status  => "error",
          :context => {:error => "Undefined method oh noes"}
        )
      end
      let!(:order_item) { create(:order_item, :topology_task_ref => task.id) }

      it "updates the item with a progress message" do
        subject.process
        progress_message = ProgressMessage.last
        expect(progress_message.level).to eq("error")
        expect(progress_message.message).to eq("Topology task error")
        expect(progress_message.order_item_id).to eq(order_item.id.to_s)
      end

      it "logs an error" do
        expect(Rails.logger).to receive(:error).with(
          "Topology error during task. State: #{task.state}. Status: #{task.status}. Context: #{task.context}"
        )
        subject.process
      end
    end
  end
end
