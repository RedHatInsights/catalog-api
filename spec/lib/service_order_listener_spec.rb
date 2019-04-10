describe ServiceOrderListener do
  let(:client) { double(:client) }

  describe "#subscribe_to_task_updates" do
    around do |example|
      ManageIQ::API::Common::Request.with_request(default_request) { example.call }
    end

    let(:message) { double("ManageIQ::Messaging::ReceivedMessage") }
    let(:update_order_item) { double("Catalog::UpdateOrderItem") }

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
      allow(Catalog::UpdateOrderItem).to receive(:new).with(message).and_return(update_order_item)
    end

    it "delegates all processing to the UpdateOrderItem serice" do
      expect(update_order_item).to receive(:process)
      subject.subscribe_to_task_updates
    end

    context "when Catalog::UpdateOrderItem#process method encounters an error" do
      before do
        allow(update_order_item).to receive(:process).and_raise("There was a big boom")
      end

      it "rescues the error" do
        expect { subject.subscribe_to_task_updates }.to_not raise_error
      end
    end
  end
end
