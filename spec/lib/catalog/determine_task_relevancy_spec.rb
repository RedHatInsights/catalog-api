describe Catalog::DetermineTaskRelevancy, :type => :service do
  describe "#process" do
    subject { described_class.new(topic) }

    let(:topic) do
      OpenStruct.new(
        :payload => {"task_id" => task_id, "status" => status, "state" => state, "output" => payload_context},
        :message => "message"
      )
    end

    let(:order) { create(:order) }
    let!(:order_item) { create(:order_item, :order => order, :topology_task_ref => "123") }

    context "when there is no relevant order item for the task id" do
      let(:task_id) { "1234" }
      let(:state) { "a" }
      let(:status) { "b" }
      let(:payload_context) { {"url" => "external_url"} }

      it "returns without doing any work" do
        expect(Catalog::UpdateOrderItem).not_to receive(:new)
        subject.process
      end
    end

    context "when an order item exists with the task id" do
      let(:task_id) { "123" }
      let(:update_order_item) { instance_double(Catalog::UpdateOrderItem) }

      before do
        allow(Catalog::UpdateOrderItem).to receive(:new).with(an_instance_of(CatalogInventoryApiClient::Task), order_item).and_return(update_order_item)
        allow(update_order_item).to receive(:process)
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
            let(:payload_context) { {"url" => "external_url"} }

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
              expect(Rails.logger).to receive(:error).with(/Order Failed/)
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
          let(:payload_context) { {"url" => "external_url"} }

          it "delegates to the UpdateOrderItem class" do
            expect(update_order_item).to receive(:process)
            subject.process
          end
        end

        context "when the context does not have a relevant keypath" do
          let(:payload_context) { nil }

          it "logs a message about irrelevant delegation" do
            expect(Rails.logger).to receive(:info).with("Topic Payload #{topic}").ordered
            expect(Rails.logger).to receive(:info).with("Incoming task #{task_id}").ordered
            expect(Rails.logger).to receive(:info).with("Delegating task #{task_id}").ordered
            expect(Rails.logger).to receive(:info).with("Incoming task has no current relevant delegation").ordered
            subject.process
          end
        end
      end
    end
  end
end
