describe Catalog::UpdateOrderItem do
  describe "#process" do
    let(:client) { double(:client) }
    let(:topic) { ManageIQ::Messaging::ReceivedMessage.new(nil, nil, payload, nil, client) }
    let(:payload) { {"task_id" => "123", "state" => state} }
    let!(:item) do
      ManageIQ::API::Common::Request.with_request(default_request) do
        create(:order_item,
               :order_id          => order.id,
               :topology_task_ref => topology_task_ref,
               :portfolio_item_id => "1")
      end
    end
    let(:order) { create(:order) }
    let(:subject) { described_class.new(topic) }

    context "when the order item is not findable" do
      let(:topology_task_ref) { "0" }
      let(:state) { "completed" }

      it "raises an error" do
        expect { subject.process }.to raise_error("Could not find an OrderItem with topology_task_ref: 123")
      end
    end

    context "when the order item is findable" do
      let(:topology_task_ref) { "123" }

      around do |e|
        with_modified_env :TOPOLOGICAL_INVENTORY_URL => 'http://localhost:3000' do
          e.run
        end
      end

      context "when the state of the task is completed" do
        let(:state) { "completed" }
        let(:task) { TopologicalInventoryApiClient::Task.new(:context => {:service_instance => {:id => "321"}}.to_json) }
        let(:service_instance) { TopologicalInventoryApiClient::ServiceInstance.new(:external_url => "external url") }

        before do
          stub_request(:get, "http://localhost:3000/api/topological-inventory/v0.1/tasks/123").
            with(:headers => {'Accept'=>'application/json', 'Content-Type'=>'application/json'}).
            to_return(:status => 200, :body => task.to_json, :headers => {})
        end

        context "when the service instance can be found" do
          before do
            stub_request(:get, "http://localhost:3000/api/topological-inventory/v0.1/service_instances/321").
              with(:headers => {'Content-Type'=>'application/json'}).
              to_return(:status => 200, :body => service_instance.to_json, :headers => {})
          end

          it "creates a progress message about the payload" do
            subject.process
            latest_progress_message = ProgressMessage.second_to_last
            expect(latest_progress_message.level).to eq("info")
            expect(latest_progress_message.message).to eq("Task update message received with payload: #{payload}")
          end

          it "updates the order item to be completed" do
            subject.process
            item.reload
            expect(item.state).to eq("Order Completed")
          end

          it "updates the order item with the external url" do
            subject.process
            item.reload
            expect(item.external_url).to eq("external url")
          end
        end

        context "when the service instance does not have an external url" do
          before do
            stub_request(:get, "http://localhost:3000/api/topological-inventory/v0.1/service_instances/321").
              with(:headers => {'Content-Type'=>'application/json'}).
              to_return(:status => 200, :body => "".to_json, :headers => {})
          end

          it "raises an error" do
            expect { subject.process }.to raise_error("Could not find an external url on service instance (id: 321) attached to task_id: 123")
          end
        end
      end

      context "when the state of the task is anything else" do
        let(:state) { "test" }

        it "creates a progress message about the payload" do
          subject.process
          latest_progress_message = ProgressMessage.last
          expect(latest_progress_message.level).to eq("info")
          expect(latest_progress_message.message).to eq("Task update message received with payload: #{payload}")
        end

        it "does not update the order" do
          subject.process
          item.reload
          expect(item.state).to eq("Created")
        end
      end
    end
  end
end
