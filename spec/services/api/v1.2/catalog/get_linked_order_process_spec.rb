describe Api::V1x2::Catalog::GetLinkedOrderProcess, :type => [:service] do
  around do |example|
    Insights::API::Common::Request.with_request(default_request) { example.call }
  end

  include_context "tag links of an order process with parameters set"

  subject { described_class.new(params) }

  shared_examples_for '#test_catalog_process' do
    it 'gets linked order processes' do
      with_modified_env test_env do
        Api::V1x2::Catalog::LinkToOrderProcess.new(params).process

        expect(subject.process.order_processes).to eq([order_process])
      end
    end
  end

  shared_examples_for '#test_remote_process' do
    it 'gets linked order processes' do
      stub_request(:get, url).to_return(:status => http_status, :body => {:data => order_process_tags}.to_json, :headers => headers)

      with_modified_env test_env do
        TagLink.create(:order_process_id => order_process.id.to_s,
                       :object_type      => object_type,
                       :app_name         => app_name,
                       :tag_name         => order_process_tag[:tag])

        expect(subject.process.order_processes).to eq([order_process])
      end
    end
  end

  describe 'catalog' do
    let(:app_name) { 'catalog' }

    context 'when object type is portfolio' do
      let(:portfolio) { create(:portfolio) }
      let(:object_id) { portfolio.id }
      let(:object_type) { 'Portfolio' }
      it_behaves_like "#test_catalog_process"
    end

    context 'when object type is portfolio_item' do
      let(:portfolio_item) { create(:portfolio_item) }
      let(:object_id) { portfolio_item.id }
      let(:object_type) { 'PortfolioItem' }
      it_behaves_like "#test_catalog_process"
    end
  end

  describe 'topology' do
    let(:object_id) { '123' }
    let(:app_name) { 'topology' }
    let(:env_not_set) { /TOPOLOGICAL_INVENTORY_URL is not set/ }

    context 'SecurityGroup' do
      let(:object_type) { 'SecurityGroup' }
      let(:url)         { "http://localhost/api/topological-inventory/v2.0/security_groups/#{object_id}/tags?limit=1000" }
      it_behaves_like "#test_remote_process"
    end

    context 'ServiceInventory' do
      let(:object_type) { 'ServiceInventory' }
      let(:url)         { "http://localhost/api/topological-inventory/v2.0/service_inventories/#{object_id}/tags?limit=1000" }
      it_behaves_like "#test_remote_process"
    end
  end

  xdescribe 'sources' do
    let(:object_id) { '123' }
    let(:app_name) { 'sources' }
    let(:env_not_set) { /SOURCES_URL is not set/ }

    context 'source' do
      let(:object_type) { 'Source' }
      let(:url)         { "http://localhost/api/sources/v1.0/sources/#{object_id}/tags?limit=1000" }
      it_behaves_like "#test_remote_process"
    end
  end
end
