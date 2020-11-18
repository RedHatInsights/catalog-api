describe Catalog::WorkspaceBuilder, :type => :sources do
  let(:order) { create(:order, :created_at => time) }
  let!(:before_item) do
    create(
      :order_item,
      :name             => 'before',
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
      :name              => 'product',
      :order_id          => order.id,
      :context           => default_request,
      :portfolio_item    => portfolio_item,
      :process_scope     => 'product',
      :process_sequence  => 2,
      :artifacts         => app_facts,
      :approval_requests => [approval_request]
    ).tap do |item|
      item.send(:service_parameters_raw=, order_params)
      item.save!
    end
  end
  let!(:after_item) do
    create(
      :order_item,
      :name             => 'after',
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
  let(:approval_request) { create(:approval_request, :reason => 'good', :state => 'approved') }
  let(:portfolio_item) { create(:portfolio_item) }
  let(:portfolio_item_process) { create(:portfolio_item) }
  let(:before_params) { {'bparam1' => 'val1', 'bparam2' => 'val2'} }
  let(:after_params)  { {'aparam1' => 'val1', 'aparam2' => 'val2'} }
  let(:order_params)  { {'mparam1' => 'val1', 'mparam2' => 'val2'} }
  let(:before_facts)  { {'before1' => 'be_val1', 'before2' => 'be_val2'} }
  let(:after_facts)   { {'after1' => 'af_val1', 'after2' => 'af_val2'} }
  let(:app_facts)     { {'app1' => 'ap_val1', 'app2' => 'ap_val2'} }
  let(:time) { Time.utc(2007, 2, 10, 20, 30, 45).in_time_zone }
  let(:source_response) { SourcesApiClient::Source.new(:name => 'the platform') }
  let(:subject) { described_class.new(order.tap { order.reload }) }

  around do |example|
    Insights::API::Common::Request.with_request(default_request) { example.call }
  end

  before do
    stub_request(:get, sources_url("sources/#{app_item.portfolio_item.service_offering_source_ref}"))
      .to_return(:status => 200, :body => source_response.to_json, :headers => default_headers)
  end

  describe '#process' do
    it 'creates a hash with required fields' do
      ws = subject.process.workspace
      expect(ws['order']['ordered_by']).to include("email" => "jdoe@acme.com", "name" => "John Doe")
      expect(ws['order']['approval']).to include('decision' => 'approved', 'reason' => 'good')
      expect(ws['order']).to include('order_id' => order.id, 'created_at' => time.iso8601)
      expect(ws['before']).to include(subject.send(:encode_name, before_item.name) => {'artifacts' => before_facts, 'parameters' => before_params, 'status' => 'Created'})
      expect(ws['after']).to include(subject.send(:encode_name, after_item.name) => {'artifacts' => after_facts, 'parameters' => after_params, 'status' => 'Created'})
      expect(ws['product']).to include(
        'artifacts'        => app_facts,
        'parameters'       => order_params,
        'status'           => 'Created',
        'name'             => portfolio_item.name,
        'description'      => portfolio_item.description,
        'long_description' => portfolio_item.long_description,
        'help_url'         => portfolio_item.documentation_url,
        'support_url'      => portfolio_item.support_url,
        'vendor'           => portfolio_item.distributor,
        'platform'         => 'the platform',
        'portfolio'        => {'name' => portfolio_item.portfolio.name, 'description' => portfolio_item.portfolio.description}
      )
    end
  end
end
