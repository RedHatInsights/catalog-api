describe Api::V1x2::Catalog::LinkToOrderProcess, :type => [:service] do
  around do |example|
    Insights::API::Common::Request.with_request(default_request) { example.call }
  end

  include_context "tag links of an order process with parameters set"

  subject { described_class.new(params) }

  shared_examples_for '#test_catalog_process' do
    it 'links a remote tag' do
      with_modified_env test_env do
        subject.process
        expect(TagLink.count).to eq(1)
        expect(TagLink.first).to have_attributes(:app_name => app_name, :object_type => object_type, :tag_name => order_process_tag[:tag])
        expect(Tag.count).to eq(1)
        expect(Tag.first).to have_attributes(:name      => Api::V1x2::Catalog::TaggingService::TAG_NAME,
                                             :namespace => Api::V1x2::Catalog::TaggingService::TAG_NAMESPACE,
                                             :value     => order_process.id.to_s)
      end
    end
  end

  shared_examples_for '#test_remote_process' do
    it 'links a remote tag' do
      with_modified_env test_env do
        stub_request(:post, url).to_return(:status => http_status, :body => order_process_tags.to_json, :headers => headers)

        subject.process
        expect(TagLink.count).to eq(1)
        expect(TagLink.first).to have_attributes(:order_process_id => order_process.id,
                                                 :app_name         => app_name,
                                                 :object_type      => object_type,
                                                 :tag_name         => order_process_tag[:tag])
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

    context 'ServiceInventory' do
      let(:object_type) { 'ServiceInventory' }
      let(:url)         { "http://localhost/api/topological-inventory/v2.0/service_inventories/#{object_id}/tag" }

      it_behaves_like "#test_remote_process"
    end
  end

  xdescribe 'sources' do
    let(:object_id) { '123' }
    let(:app_name) { 'sources' }
    let(:env_not_set) { /SOURCES_URL is not set/ }

    context 'source' do
      let(:object_type) { 'Source' }
      let(:url)         { "http://localhost/api/sources/v1.0/sources/#{object_id}/tag" }

      it_behaves_like "#test_remote_process"
    end
  end
end
