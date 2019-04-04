describe ServiceOrderListener do
  let(:client) { double(:client) }

  describe "#subscribe_to_task_updates" do
    let(:request) do
      { :headers => { 'x-rh-identity' => encoded_user_hash }, :original_url => 'whatever' }
    end

    around do |example|
      ManageIQ::API::Common::Request.with_request(request) { example.call }
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
  end
end
