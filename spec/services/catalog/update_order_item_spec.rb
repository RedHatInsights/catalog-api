describe Catalog::UpdateOrderItem, :type => :service do
  let(:subject) { described_class.new(topic, task) }
  let(:topic) { Struct.new(:payload, :message).new(payload, "message") }
  let(:task) { TopologicalInventoryApiClient::Task.new(:context => {:service_instance => {:id => "321"}}) }

  describe "#process" do
    let(:payload) { {"task_id" => "123", "status" => status, "state" => state, "context" => "payloadcontext"} }
    let!(:item) { create(:order_item, :topology_task_ref => topology_task_ref) }
    let(:order) { item.order }

    around do |example|
      with_modified_env(:TOPOLOGICAL_INVENTORY_URL => "http://topology.example.com") do
        example.call
      end
    end

    before do
      allow(Insights::API::Common::Request).to receive(:current_forwardable).and_return(default_headers)
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
      let(:service_instance) { TopologicalInventoryApiClient::ServiceInstance.new(:external_url => external_url) }
      let(:external_url) { "external url" }
      let(:topology_task_ref) { "123" }

      before do
        stub_request(:get, topological_url("service_instances/321")).to_return(
          :status  => 200,
          :body    => service_instance.to_json,
          :headers => default_headers
        )
      end

      context "when the status of the task is ok" do
        let(:status) { "ok" }

        context "when the state is completed" do
          let(:state) { "completed" }

          before do
            stub_request(:get, topological_url("service_instances/321")).to_return(
              :status  => 200,
              :body    => service_instance.to_json,
              :headers => default_headers
            )
          end

          shared_examples_for "#process when it all goes well" do
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

            it "finalizes the order" do
              expect(order.state).to_not eq("Completed")
              subject.process
              order.reload
              expect(order.state).to eq("Completed")
            end
          end

          context "when the service instance has an external url" do
            it_behaves_like "#process when it all goes well"

            it "updates the order item with the external url" do
              subject.process
              item.reload
              expect(item.external_url).to eq("external url")
            end
          end

          context "when the service instance does not have an external url" do
            let(:external_url) { nil }

            it_behaves_like "#process when it all goes well"

            it "sets the external_url to nil" do
              subject.process
              item.reload
              expect(item.external_url).to eq(nil)
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

        it "sets the service_instance_ref" do
          subject.process
          item.reload
          expect(item.service_instance_ref).to eq("321")
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

      context "when the item had been marked failed before and the task does not have a service instance id" do
        let(:status) { "error" }
        let(:state) { "bar" }
        let(:task) { TopologicalInventoryApiClient::Task.new(:context => {}) }

        before do
          item.update(:service_instance_ref => "321")
          item.reload
        end

        it "sets the external url" do
          subject.process
          item.reload
          expect(item.external_url).to eq("external url")
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
