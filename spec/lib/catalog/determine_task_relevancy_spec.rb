describe Catalog::DetermineTaskRelevancy, :type => :service do
  describe "#process" do
    subject { described_class.new(topic) }

    let(:topic) do
      OpenStruct.new(
        :payload => {"task_id" => task_id, "status" => status, "state" => state, "context" => payload_context},
        :message => "message"
      )
    end

    let!(:order_item) { create(:order_item, :topology_task_ref => "123") }

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
      let(:update_order_item) { instance_double(Catalog::UpdateOrderItem) }
      let(:create_approval_request) { instance_double(Catalog::CreateApprovalRequest) }

      before do
        allow(Catalog::UpdateOrderItem).to receive(:new).with(topic, an_instance_of(TopologicalInventoryApiClient::Task), order_item).and_return(update_order_item)
        allow(update_order_item).to receive(:process)
        allow(Catalog::CreateApprovalRequest).to receive(:new).with(an_instance_of(TopologicalInventoryApiClient::Task), order_item).and_return(create_approval_request)
        allow(create_approval_request).to receive(:process)
      end

      context "when the task status is error" do
        let(:status) { "error" }

        context "when the task state is running" do
          let(:state) { "running" }
          let(:payload_context) { {"test" => "test"} }

          it "logs an error message" do
            expect(Rails.logger).to receive(:error).with("Incoming task 123 had an error while running: #{payload_context}")
            subject.process
          end
        end

        context "when the task state is completed" do
          let(:state) { "completed" }
          let(:payload_context) { {"test" => "test"} }

          shared_examples_for "#process that errors and is complete" do
            it "logs an error message" do
              expect(Rails.logger).to receive(:error).with("Incoming task 123 is completed but errored: #{payload_context}")
              subject.process
            end

            it "marks the item as failed" do
              expect do
                subject.process
                order_item.reload
              end.to change { order_item.state }.from("Created").to("Failed")
            end
          end

          context "when the context has a service instance keypath" do
            let(:payload_context) { {"service_instance" => "service instance stuff"} }

            it "delegates to the UpdateOrderItem class" do
              expect(update_order_item).to receive(:process)
              subject.process
            end

            it_behaves_like "#process that errors and is complete"
          end

          context "when the context has an applied inventories keypath" do
            let(:payload_context) { {"applied_inventories" => "applied inventories stuff"} }

            it "delegates to the CreateApprovalRequest class" do
              expect(create_approval_request).to receive(:process)
              subject.process
            end

            it "logs a message about creating an approval request as a response to a task id" do
              expect(Rails.logger).to receive(:info).with("Creating approval request for task id 123")
              subject.process
            end

            it_behaves_like "#process that errors and is complete"
          end

          context "when the context does not have a relevant keypath" do
            let(:payload_context) { nil }

            it "logs a message about irrelevant delegation" do
              expect(Rails.logger).to receive(:info).with("Incoming task has no current relevant delegation")
              subject.process
            end

            it_behaves_like "#process that errors and is complete"
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
          let(:payload_context) { {"applied_inventories" => "applied inventories stuff"} }

          it "delegates to the CreateApprovalRequest class" do
            expect(create_approval_request).to receive(:process)
            subject.process
          end

          it "logs a message about creating an approval request as a response to a task id" do
            expect(Rails.logger).to receive(:info).with("Creating approval request for task id 123")
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
