describe Catalog::DetermineTaskRelevancy, :type => :service do
  describe "#process" do
    subject { described_class.new(topic) }

    let(:topic) do
      OpenStruct.new(
        :payload => {"task_id" => task_id, "status" => status, "state" => state, "context" => payload_context},
        :message => "message"
      )
    end

    let(:order) { create(:order) }
    let!(:order_item) { create(:order_item, :order => order, :topology_task_ref => "123") }

    context "when there is no relevant order item for the task id" do
      let(:task_id) { "1234" }
      let(:state) { "a" }
      let(:status) { "b" }
      let(:payload_context) { {"service_instance" => {"url" => "external_url"}} }

      it "logs a message about irrelevancy" do
        expect(Rails.logger).to receive(:info).with("Incoming task 1234 has no relevant order item")
        subject.process
      end

      it "returns without doing any work" do
        expect(Catalog::UpdateOrderItem).not_to receive(:new)
        expect(Catalog::CreateApprovalRequest).not_to receive(:new)
        subject.process
      end
    end

    context "when an order item exists with the task id" do
      let(:task_id) { "123" }
      let(:tag_resources) { [] }
      let(:update_order_item) { instance_double(Catalog::UpdateOrderItem) }
      let(:create_approval_request) { instance_double(Catalog::CreateApprovalRequest) }
      let(:evaluate_order_process) { instance_double(Catalog::EvaluateOrderProcess) }
      let(:tag_resources_instance) { instance_double(Tags::CollectTagResources) }

      before do
        allow(Catalog::UpdateOrderItem).to receive(:new).with(an_instance_of(TopologicalInventoryApiClient::Task), order_item).and_return(update_order_item)
        allow(update_order_item).to receive(:process)
        allow(Catalog::CreateApprovalRequest).to receive(:new).with(an_instance_of(TopologicalInventoryApiClient::Task), tag_resources, order_item).and_return(create_approval_request)
        allow(create_approval_request).to receive(:process)
        allow(Catalog::EvaluateOrderProcess).to receive(:new).with(an_instance_of(TopologicalInventoryApiClient::Task), order, tag_resources).and_return(evaluate_order_process)
        allow(evaluate_order_process).to receive(:process)
        allow(Tags::CollectTagResources).to receive(:new).and_return(tag_resources_instance)
        allow(tag_resources_instance).to receive(:process).and_return(tag_resources_instance)
        allow(tag_resources_instance).to receive(:tag_resources).and_return(tag_resources)
      end

      context "when the task status is error" do
        let(:status) { "error" }

        context "when the task state is running" do
          let(:state) { "running" }
          let(:payload_context) { {"test" => "test"} }

          it "logs an error and adds a progress message" do
            expect(Rails.logger).to receive(:error).with("Incoming task 123 had an error while running: #{payload_context}")
            subject.process
            order_item.reload
            expect(order_item.progress_messages.size).to eq(1)
            expect(order_item.state).to eq("Created")
          end
        end

        context "when the task state is completed" do
          let(:state) { "completed" }

          context "when the context has a service instance keypath" do
            let(:payload_context) { {"service_instance" => "service instance stuff"} }

            it "updates the order item using the update service" do
              expect(Rails.logger).to receive(:error).with("Incoming task 123 is completed but errored: #{payload_context}")
              expect(update_order_item).to receive(:process)
              subject.process
            end
          end

          context "when the context does not have a service keypath" do
            let(:payload_context) { {"test" => "test"} }

            it "fails the order, log errors, and adds a progress message" do
              expect(Rails.logger).to receive(:error).with("Incoming task 123 is completed but errored: #{payload_context}")
              expect(Rails.logger).to receive(:error).with(/Updated OrderItem: \d+ with 'Failed'/)
              subject.process
              order_item.reload
              expect(order_item.progress_messages.size).to eq(2)
              expect(order_item.state).to eq('Failed')
            end
          end
        end
      end

      context "when the task status is not error" do
        let(:status) { "ok" }
        let(:state) { "doesn't matter" }

        context "when the context has a service instance keypath" do
          let(:payload_context) { {"service_instance" => "service instance stuff"} }

          it "delegates to the UpdateOrderItem class" do
            expect(update_order_item).to receive(:process)
            subject.process
          end
        end

        context "when the context has an applied inventories keypath" do
          let(:payload_context) { {"applied_inventories" => ["applied_inventory_id"]} }

          it "delegates to the CreateApprovalRequest class" do
            expect(evaluate_order_process).to receive(:process)
            expect(create_approval_request).to receive(:process)
            subject.process
          end

          it "logs a message about creating an approval request as a response to a task id" do
            expect(Rails.logger).to receive(:info).with("Evaluating order processes for order item id #{order_item.id}").ordered
            expect(Rails.logger).to receive(:info).with("Creating approval request for task id 123").ordered
            subject.process
          end
        end

        context "when the context does not have a relevant keypath" do
          let(:payload_context) { nil }

          it "logs a message about irrelevant delegation" do
            expect(Rails.logger).to receive(:info).with("Incoming task has no current relevant delegation")
            subject.process
          end
        end
      end
    end
  end
end
