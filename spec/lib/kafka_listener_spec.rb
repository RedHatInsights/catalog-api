describe KafkaListener do
  let(:test_listener_class) do
    Class.new(described_class) do
      def process_event(_event)
      end
    end
  end

  let(:client) { double(:client) }
  let(:service) { 'service' }
  let(:persist_ref) { 'ref' }
  let(:subject) { test_listener_class.new({:host => 'localhost', :port => 9092}, service, persist_ref) }
  let(:headers) { default_headers }
  let(:event) { ManageIQ::Messaging::ReceivedMessage.new(nil, 'test event', {'data' => 'value'}, headers, nil, client) }

  before do
    allow(ManageIQ::Messaging::Client).to receive(:open).with(
      :encoding => "json",
      :host     => "localhost",
      :port     => 9092,
      :protocol => :Kafka
    ).and_yield(client)

    allow(client).to receive(:subscribe_topic).with(
      :service     => service,
      :persist_ref => persist_ref,
      :max_bytes   => 500_000
    ).and_yield(event)

    allow(event).to receive(:ack)
  end

  describe "message headers are not complete" do
    shared_examples_for "with bad headers" do
      it "skips the message" do
        expect(subject).not_to receive(:process_event)
        subject.subscribe
      end
    end

    context "when x-rh-identity is missing" do
      let(:headers) { default_headers.except('x-rh-identity') }

      it_behaves_like "with bad headers"
    end

    context "when x-rh-insights-request-id is missing" do
      let(:headers) { default_headers.except('x-rh-insights-request-id') }

      it_behaves_like "with bad headers"
    end

    context "when x-rh-identity contains a non-exist tenant" do
      it_behaves_like "with bad headers"
    end

    context "when x-rh-identity contains a valid tenant" do
      before { Tenant.create(:external_tenant => '0369233') }

      it 'processes the event' do
        expect(subject).to receive(:process_event).with(event)
        subject.subscribe
      end
    end
  end

  context "when the event processing has an error" do
    before do
      Tenant.create(:external_tenant => '0369233')
      allow(subject).to receive(:process_event).and_raise(StandardError)
    end

    it "does not spin forever" do
      expect(client).to receive(:subscribe_topic).once

      Timeout.timeout(3) do
        subject.subscribe
      end
    end

    it "acks the event" do
      expect(event).to receive(:ack)
      subject.subscribe
    end

    it "logs an error" do
      expect(Rails.logger).to receive(:error).with(/Error processing event/)
      subject.subscribe
    end
  end
end
