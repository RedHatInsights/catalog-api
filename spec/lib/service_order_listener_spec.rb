describe ServiceOrderListener do
  let(:client) { double(:client) }

  describe "#subscribe_to_task_updates" do
    let(:request) do
      { :headers => { 'x-rh-identity' => encoded_user_hash }, :original_url => 'whatever' }
    end

    around do |example|
      ManageIQ::API::Common::Request.with_request(request) { example.call }
    end

    let(:message) { ManageIQ::Messaging::ReceivedMessage.new(nil, nil, payload, nil) }
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

    before do
      allow(ManageIQ::Messaging::Client).to receive(:open).with(
        :protocol   => :Kafka,
        :client_ref => ServiceOrderListener::CLIENT_REF,
        :encoding   => "json"
      ).and_yield(client)
      allow(client).to receive(:subscribe_topic).with(
        :service     => ServiceOrderListener::SERVICE_NAME,
        :persist_ref => ServiceOrderListener::CLIENT_REF,
        :max_bytes   => 500_000
      ).and_yield(message)
      allow(client).to receive(:close)
    end

    context "when the order item is not findable" do
      let(:topology_task_ref) { "0" }

      context "when the state of the task is anything else" do
        let(:state) { "test" }

        it "creates a progress message about the payload" do
          subject.subscribe_to_task_updates
          latest_progress_message = ProgressMessage.last
          expect(latest_progress_message.level).to eq("info")
          expect(latest_progress_message.message).to eq("Task update message received with payload: #{payload}")
        end
      end

      context "when the state of the task is completed" do
        let(:state) { "completed" }

        it "creates a progress message about the payload" do
          subject.subscribe_to_task_updates
          latest_progress_message = ProgressMessage.second_to_last
          expect(latest_progress_message.level).to eq("info")
          expect(latest_progress_message.message).to eq("Task update message received with payload: #{payload}")
        end

        it "creates a progress message with an error" do
          subject.subscribe_to_task_updates
          latest_progress_message = ProgressMessage.last
          expect(latest_progress_message.level).to eq("error")
          expect(latest_progress_message.message).to eq("Could not find OrderItem with topology_task_ref of 123")
        end
      end
    end

    context "when the order item is findable" do
      let(:topology_task_ref) { "123" }

      context "when the state of the task is anything else" do
        let(:state) { "test" }

        it "creates a progress message about the payload" do
          subject.subscribe_to_task_updates
          latest_progress_message = ProgressMessage.last
          expect(latest_progress_message.level).to eq("info")
          expect(latest_progress_message.message).to eq("Task update message received with payload: #{payload}")
        end

        it "does not update the order" do
          subject.subscribe_to_task_updates
          item.reload
          expect(item.state).to eq("Created")
        end
      end

      context "when the state of the task is completed" do
        let(:state) { "completed" }

        it "creates a progress message about the payload" do
          subject.subscribe_to_task_updates
          latest_progress_message = ProgressMessage.second_to_last
          expect(latest_progress_message.level).to eq("info")
          expect(latest_progress_message.message).to eq("Task update message received with payload: #{payload}")
        end

        it "updates the order item to be completed" do
          subject.subscribe_to_task_updates
          item.reload
          expect(item.state).to eq("Order Completed")
        end
      end
    end
  end
end
