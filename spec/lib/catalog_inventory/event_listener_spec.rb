describe CatalogInventory::EventListener do
  let(:client) { double(:client) }
  let(:subject) { described_class.new(:host => 'localhost', :port => 9092) }

  before do
    allow(ManageIQ::Messaging::Client).to receive(:open).with(
      :encoding => "json",
      :host     => "localhost",
      :port     => 9092,
      :protocol => :Kafka
    ).and_yield(client)

    allow(client).to receive(:subscribe_topic).with(
      :service     => described_class::SERVICE_NAME,
      :persist_ref => described_class::GROUP_REF,
      :max_bytes   => 500_000
    ).and_yield(event)

    allow(event).to receive(:ack)
  end

  context 'when event_type is Task.update' do
    let(:order) { create(:order) }
    let!(:order_item) { create(:order_item, :order => order, :topology_task_ref => "123") }
    let(:payload_context) { {"service_instance" => {"url" => "external_url"}} }
    let(:payload) { {'id' => "123", "status" => "ok", "state" => "running", "context" => payload_context} }
    let(:event) { ManageIQ::Messaging::ReceivedMessage.new(nil, 'Task.update', payload, default_headers, nil, client) }

    it 'adds a new progress message' do
      subject.subscribe
      progress_message = ProgressMessage.last
      expect(progress_message.level).to eq("info")
      expect(progress_message.message).to eq("Order Item Is Running")
      expect(progress_message.messageable_id).to eq(order_item.id)
      expect(progress_message.messageable_type).to eq(order_item.class.name)
      order_item.reload
      expect(order_item.external_url).to eq("external_url")
    end

    it 'fails the order if an error happens' do
      allow(Catalog::DetermineTaskRelevancy).to receive(:new).and_raise("Bad happened")

      subject.subscribe
      order.reload
      order_item.reload
      expect(order.state).to eq('Failed')
      expect(order_item.state).to eq('Failed')
    end
  end
end
