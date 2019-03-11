require "manageiq-messaging"

describe ServiceOrderListener do
  let(:client) { double(:client) }

  describe "#run" do
    let(:messages) { [ManageIQ::Messaging::ReceivedMessage.new(nil, nil, payload, nil)] }
    let(:payload) { {"task_id" => "123", "state" => state} }
    let!(:item) do
      OrderItem.create!(
        :count                       => 1,
        :service_parameters          => "test",
        :provider_control_parameters => "test",
        :order                       => order,
        :service_plan_ref            => "321",
        :portfolio_item              => portfolio_item,
        :topology_task_ref           => "123"
      )
    end
    let(:order) { Order.create! }
    let(:portfolio_item) { PortfolioItem.create!(:service_offering_ref => "321") }

    before do
      allow(ManageIQ::Messaging::Client).to receive(:open).and_return(client)
      allow(client).to receive(:subscribe_messages).with(
        :service   => "platform.topological-inventory.task-output-stream",
        :max_bytes => 500_000
      ).and_yield(messages)
    end

    context "when the state of the task is completed" do
      let(:state) { "completed" }

      it "updates the order item to be completed" do
        subject.run.join
        item.reload
        expect(item.state).to eq("Order Completed?")
      end
    end
  end
end
