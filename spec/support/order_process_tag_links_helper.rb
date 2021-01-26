RSpec.shared_context "tag links of an order process with parameters set" do
  let(:order_process_tag) do
    {:tag => "/#{Api::V1x2::Catalog::TaggingService::TAG_NAMESPACE}/#{Api::V1x2::Catalog::TaggingService::TAG_NAME}=#{order_process.id}"}
  end

  let(:order_process_tags) { [order_process_tag] }
  let(:http_status) { [200, 'Ok'] }
  let(:headers)     do
    {'Content-Type' => 'application/json'}.merge(default_headers)
  end

  let(:test_env) do
    {
      :CATALOG_INVENTORY_URL     => 'http://inventory.example.com',
      :CATALOG_URL               => 'http://catalog.example.com',
      :SOURCES_URL               => 'http://sources.example.com'
    }
  end

  let(:order_process) { create(:order_process) }

  let(:params) do
    ActionController::Parameters.new('id'          => order_process.id,
                                     'object_id'   => object_id,
                                     'object_type' => object_type,
                                     'app_name'    => app_name)
  end
end
