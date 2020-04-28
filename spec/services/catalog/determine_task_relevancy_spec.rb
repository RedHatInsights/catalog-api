describe Catalog::DetermineTaskRelevancy, :type => :service do
  let(:subject) { described_class.new(topic) }
  let(:topic) do
    OpenStruct.new(
      :payload => {"task_id" => "123", "status" => status, "state" => state, "context" => payload_context},
      :message => "message"
    )
  end

  let!(:order_item) { create(:order_item, :topology_task_ref => "123") }
  let(:order_state_transition) { instance_double(Catalog::OrderStateTransition) }

  describe "#process" do
    context "when the state is running" do
      let(:state) { "running" }
      let(:status) { "ok" }
      let(:payload_context) { {"service_instance" => {"url" => "external_url"}} }

      it "updates the item with a progress message" do
        subject.process
        progress_message = ProgressMessage.last
        expect(progress_message.level).to eq("info")
        expect(progress_message.message).to match(/Order Item being processed with context.*external_url/)
        expect(progress_message.order_item_id).to eq(order_item.id.to_s)
      end

      it "sets the external_url from the payload" do
        subject.process
        order_item.reload
        expect(order_item.external_url).to eq "external_url"
      end
    end

    context "when the state is something else" do
      let(:state) { "what" }
      let(:status) { "ok" }
      let(:payload_context) { nil }

      it "updates the item with a progress message" do
        subject.process
        progress_message = ProgressMessage.last
        expect(progress_message.level).to eq("info")
        expect(progress_message.message).to match(/Task update/)
        expect(progress_message.order_item_id).to eq(order_item.id.to_s)
      end
    end

    context "when the state is completed" do
      let(:state) { "completed" }
      let(:status) { "ok" }

      context "when the task context has a key path of [:service_instance][:id]" do
        let(:payload_context) { {"service_instance" => {"id" => "321"}} }
        let(:update_order_item) { instance_double("Catalog::UpdateOrderItem") }

        before do
          allow(Catalog::UpdateOrderItem).to receive(:new).and_return(update_order_item)
          allow(update_order_item).to receive(:process)
        end

        context "success scenario" do
          before do
            allow(update_order_item).to receive(:process)
          end
          it "updates the item with a progress message" do
            subject.process
            progress_message = ProgressMessage.last
            expect(progress_message.level).to eq("info")
            expect(progress_message.message).to match(/Task update. State: completed/)
            expect(progress_message.order_item_id).to eq(order_item.id.to_s)
          end

          it "delegates to updating the order item" do
            expect(update_order_item).to receive(:process)
            subject.process
          end
        end

        context "error scenario" do
          it "raises StandardError" do
            allow(update_order_item).to receive(:process).and_raise(StandardError)
            expect(Rails.logger).to receive(:error).once
            expect { subject.process }.to raise_exception(StandardError)
          end
        end
      end

      context "when the task context has a key path of [:applied_inventories]" do
        let(:payload_context) { {"applied_inventories" => ["1", "2"]} }
        let(:create_approval_request) { instance_double("Catalog::CreateApprovalRequest") }
        let(:task) do
          TopologicalInventoryApiClient::Task.new(
            :id      => "123",
            :state   => "completed",
            :status  => "ok",
            :context => {"applied_inventories" => ["1", "2"]}
          )
        end

        before do
          allow(Catalog::CreateApprovalRequest).to receive(:new).with(task).and_return(create_approval_request)
          allow(create_approval_request).to receive(:process)
        end

        it "creates a task with id, state, status and context" do
          expect(TopologicalInventoryApiClient::Task).to receive(:new).with(
            :id      => "123",
            :state   => "completed",
            :status  => "ok",
            :context => {"applied_inventories" => ["1", "2"]}
          ).and_return(task)
          subject.process
        end

        it "updates the item with a progress message" do
          subject.process
          progress_message = ProgressMessage.last
          expect(progress_message.level).to eq("info")
          expect(progress_message.message).to match(/Task update. State: completed/)
          expect(progress_message.order_item_id).to eq(order_item.id.to_s)
        end

        it "delegates to creating the approval request" do
          expect(create_approval_request).to receive(:process)
          subject.process
        end

        it "updates the item with a task progress message before delgation" do
          subject.instance_variable_set(:@order_item, order_item)
          expect(order_item).to receive(:update_message).with(:info, /Task update. State: completed/).ordered
          expect(create_approval_request).to receive(:process).ordered
          subject.process
        end
      end

      context "when the task context does not have either key path" do
        let(:payload_context) { {"error" => "Undefined method oh noes"} }

        context "when the status is 'error'" do
          let(:status) { "error" }

          before do
            allow(Catalog::OrderStateTransition).to receive(:new).with(order_item.order).and_return(order_state_transition)
            allow(order_state_transition).to receive(:process)
          end

          it "updates the item with a progress message" do
            subject.process
            progress_message = ProgressMessage.last
            expect(progress_message.level).to eq("error")
            expect(progress_message.message).to match(/Task update/)
            expect(progress_message.order_item_id).to eq(order_item.id.to_s)
          end

          it "transitions the order state and marks the order item failed" do
            expect(order_state_transition).to receive(:process)
            subject.process
            order_item.reload
            expect(order_item.state).to eq("Failed")
          end
        end

        context "when the status is not 'error'" do
          let(:status) { "updated" }

          before do
            allow(Rails.logger).to receive(:info).with(anything)
          end

          it "updates the item with a progress message" do
            subject.process
            progress_message = ProgressMessage.last
            expect(progress_message.level).to eq("info")
            expect(progress_message.message).to match(/Task update/)
            expect(progress_message.order_item_id).to eq(order_item.id.to_s)
          end
        end
      end
    end
  end
end
