describe Catalog::UpdateOrderItem do
  describe "#process" do
    around do |example|
      ManageIQ::API::Common::Request.with_request(default_request) { example.call }
    end

    let(:client) { double(:client) }
    let(:topic) { ManageIQ::Messaging::ReceivedMessage.new(nil, nil, payload, nil, client) }
    let(:payload) { {"task_id" => "123", "state" => state} }
    let!(:item) do
      OrderItem.create!(
        :count                       => 1,
        :service_parameters          => "test",
        :provider_control_parameters => "test",
        :order                       => order,
        :service_plan_ref            => "321",
        :portfolio_item              => portfolio_item,
        :topology_task_ref           => topology_task_ref
      )
    end
    let(:order) { Order.create! }
    let(:portfolio_item) { PortfolioItem.create!(:service_offering_ref => "321") }
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

      context "when the state of the task is completed" do
        let(:state) { "completed" }

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
