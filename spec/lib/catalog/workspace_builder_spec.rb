describe Catalog::WorkspaceBuilder do
  let(:order) { create(:order, :order_request_sent_at => time) }
  let!(:before_item) do
    create(
      :order_item,
      :order_id         => order.id,
      :context          => default_request,
      :portfolio_item   => portfolio_item_process,
      :process_scope    => 'before',
      :process_sequence => 1,
      :artifacts        => before_facts
    ).tap do |item|
      item.send(:service_parameters_raw=, before_params)
      item.save!
    end
  end
  let!(:app_item) do
    create(
      :order_item,
      :order_id         => order.id,
      :context          => default_request,
      :portfolio_item   => portfolio_item,
      :process_scope    => 'applicable',
      :process_sequence => 2,
      :artifacts        => app_facts
    ).tap do |item|
      item.send(:service_parameters_raw=, order_params)
      item.save!
    end
  end
  let!(:after_item) do
    create(
      :order_item,
      :order_id         => order.id,
      :context          => default_request,
      :portfolio_item   => portfolio_item_process,
      :process_scope    => 'after',
      :process_sequence => 3,
      :artifacts        => after_facts
    ).tap do |item|
      item.send(:service_parameters_raw=, after_params)
      item.save!
    end
  end
  let(:portfolio_item) { create(:portfolio_item) }
  let(:portfolio_item_process) { create(:portfolio_item) }
  let(:before_params) { {'bparam1' => 'val1', 'bparam2' => 'val2'} }
  let(:after_params)  { {'aparam1' => 'val1', 'aparam2' => 'val2'} }
  let(:order_params)  { {'mparam1' => 'val1', 'mparam2' => 'val2'} }
  let(:before_facts)  { {'before1' => 'be_val1', 'before2' => 'be_val2'} }
  let(:after_facts)   { {'after1' => 'af_val1', 'after2' => 'af_val2'} }
  let(:app_facts)     { {'app1' => 'ap_val1', 'app2' => 'ap_val2'} }
  let(:time) { DateTime.new(2001, 2, 3, 4, 5, 6, "-530") }
  let(:subject) { described_class.new(order.tap { order.reload }) }

  around do |example|
    Insights::API::Common::Request.with_request(default_request) { example.call }
  end

  describe '#process' do
    it 'creates a hash with required fields' do
      ws = subject.process.workspace
      expect(ws['user']).to include("email" => "jdoe@acme.com", "name" => "John Doe")
      expect(ws['request']).to include('order_id' => order.id, 'order_started' => time.utc)
      expect(ws['before']).to include(portfolio_item_process.name => {'artifacts' => before_facts, 'extra_vars' => before_params, 'status' => 'Created'})
      expect(ws['after']).to include(portfolio_item_process.name => {'artifacts' => after_facts, 'extra_vars' => after_params, 'status' => 'Created'})
      expect(ws['applicable']).to include(portfolio_item.name => {'artifacts' => app_facts, 'extra_vars' => order_params, 'status' => 'Created'})
    end
  end
end
