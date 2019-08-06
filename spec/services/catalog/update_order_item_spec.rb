require "manageiq-messaging"

describe Catalog::UpdateOrderItem do
  describe "#process" do
    let(:client) { double(:client) }
    let(:topic) { ManageIQ::Messaging::ReceivedMessage.new(nil, nil, payload, nil, client, nil) }
    let(:payload) { {"task_id" => "123", "status" => status, "state" => state, "context" => "payloadcontext"} }
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
    let(:api_instance) { instance_double("TopologicalInventoryApiClient::DefaultApi") }
    let(:ti_class) { class_double("TopologicalInventory").as_stubbed_const(:transfer_nested_constants => true) }

    before do
      allow(ti_class).to receive(:call).and_yield(api_instance)
    end

    context "when the order item is not findable" do
      let(:topology_task_ref) { "0" }
      let(:status) { "ok" }
      let(:state) { "bar" }

      it "raises an error" do
        expect { subject.process }.to raise_error("Could not find an OrderItem with topology_task_ref: 123")
      end
    end

    context "when the order item is findable" do
      let(:topology_task_ref) { "123" }
      let(:service_instance_id) { "321" }

      context "when the status of the task is ok" do
        let(:status) { "ok" }
        let(:task) { TopologicalInventoryApiClient::Task.new(:context => {:service_instance => {:id => service_instance_id}}.to_json) }
        let(:service_instance) { TopologicalInventoryApiClient::ServiceInstance.new(:external_url => "external url") }
        let(:service_instance_no_external_url) { TopologicalInventoryApiClient::ServiceInstance.new }

        before do
          allow(ti_class).to receive(:call).and_yield(api_instance)
          allow(api_instance).to receive(:show_task).with(topology_task_ref).and_return(task)
        end

        context "when the state is completed" do
          let(:state) { "completed" }

          context "when the service instance can be found" do
            before do
              allow(api_instance).to receive(:show_service_instance).with(service_instance_id).and_return(service_instance)
            end

            it "creates a progress message about the payload" do
              subject.process
              latest_progress_message = ProgressMessage.second_to_last
              expect(latest_progress_message.level).to eq("info")
              expect(latest_progress_message.message).to eq("Task update message received with payload: #{payload}")
            end

            it "updates the completed at time" do
              fake_now = Time.now.iso8601
              allow(DateTime).to receive(:now).and_return(fake_now)
              subject.process
              item.reload
              expect(item.completed_at).to eq(fake_now)
            end

            it "updates the order item to be completed" do
              subject.process
              item.reload
              expect(item.state).to eq("Completed")
            end

            it "creates a progress message about the completion" do
              subject.process
              latest_progress_message = ProgressMessage.last
              expect(latest_progress_message.level).to eq("info")
              expect(latest_progress_message.message).to eq("Order Item Complete")
            end

            it "updates the order item with the external url" do
              subject.process
              item.reload
              expect(item.external_url).to eq("external url")
            end

            it "finalizes the order" do
              expect(order.state).to_not eq("Completed")
              subject.process
              order.reload
              expect(order.state).to eq("Completed")
            end
          end

          context "when the service instance does not have an external url" do
            before do
              allow(api_instance).to receive(:show_service_instance).with(service_instance_id).and_return(service_instance_no_external_url)
            end

            it "updates the order item to be completed" do
              subject.process
              item.reload
              expect(item.state).to eq("Completed")
            end

            it "creates a progress message about the completion" do
              subject.process
              latest_progress_message = ProgressMessage.last
              expect(latest_progress_message.level).to eq("info")
              expect(latest_progress_message.message).to eq("Order Item Complete")
            end

            it "sets the external_url to nil" do
              subject.process
              item.reload
              expect(item.external_url).to eq(nil)
            end

            it "finalizes the order" do
              expect(order.state).to_not eq("Completed")
              subject.process
              order.reload
              expect(order.state).to eq("Completed")
            end
          end
        end

        context "when the state is running" do
          let(:state) { "running" }

          it "creates multiple progress messages" do
            subject.process
            payload_progress_message, context_progress_message = ProgressMessage.last(2)
            expect(payload_progress_message.level).to eq("info")
            expect(context_progress_message.level).to eq("info")
            expect(payload_progress_message.message).to eq("Task update message received with payload: #{payload}")
            expect(context_progress_message.message).to eq("Order Item being processed with context: payloadcontext")
          end
        end
      end

      context "when the status of the task is error" do
        let(:status) { "error" }
        let(:state) { "bar" }

        it "creates a progress message about the payload" do
          subject.process
          latest_progress_message = ProgressMessage.second_to_last
          expect(latest_progress_message.level).to eq("info")
          expect(latest_progress_message.message).to eq("Task update message received with payload: #{payload}")
        end

        it "updates the completed at time" do
          fake_now = Time.now.iso8601
          allow(DateTime).to receive(:now).and_return(fake_now)
          subject.process
          item.reload
          expect(item.completed_at).to eq(fake_now)
        end

        it "marks the item as failed" do
          subject.process
          item.reload
          expect(item.state).to eq("Failed")
        end

        it "creates a progress message about the failure" do
          subject.process
          latest_progress_message = ProgressMessage.last
          expect(latest_progress_message.level).to eq("error")
          expect(latest_progress_message.message).to eq("Order Item Failed")
        end

        it "finalizes the order" do
          expect(order.state).to_not eq("Failed")
          subject.process
          order.reload
          expect(order.state).to eq("Failed")
        end
      end

      context "when the status of the task is anything else" do
        let(:status) { "foo" }
        let(:state) { "bar" }

        it "creates a progress message about the payload" do
          subject.process
          latest_progress_message = ProgressMessage.last
          expect(latest_progress_message.level).to eq("info")
          expect(latest_progress_message.message).to eq("Task update message received with payload: #{payload}")
        end
      end
    end
  end
end
