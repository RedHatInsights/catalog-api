describe Approval::EventListener do
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
  end

  context 'when event_type is workflow_deleted' do
    let(:portfolio) { create(:portfolio) }
    let(:payload) { {'workflow_id' => 5} }
    let(:event) { ManageIQ::Messaging::ReceivedMessage.new(nil, described_class::EVENT_WORKFLOW_DELETED, payload, default_headers, nil, client) }

    before { portfolio.tag_add('workflows', :namespace => 'approval', :value => '5') }

    it 'finds and deletes the tag associated with the workflow' do
      expect(Tag.count).to eq(1)
      subject.subscribe
      expect(Tag.count).to be_zero
    end
  end

  context 'when event_type is request_finished' do
    let(:approval_request) { create(:approval_request, :has_tenant) }
    let(:payload) { {'request_id' => approval_request.approval_request_ref, 'decision' => 'denied', 'reason' => 'bad'} }
    let(:event) { ManageIQ::Messaging::ReceivedMessage.new(nil, Catalog::NotifyApprovalRequest::EVENT_REQUEST_FINISHED, payload, default_headers, nil, client) }

    it 'updates approval_request' do
      expect(Catalog::ApprovalTransition).to receive(:new).and_return(instance_double(Catalog::ApprovalTransition, :process => nil))

      subject.subscribe
      approval_request.reload
      expect(approval_request).to have_attributes(
        :state  => 'denied',
        :reason => 'bad'
      )
    end
  end
end
