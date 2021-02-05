describe Tags::CatalogInventory::RemoteInventory, :type => :service do
  let(:portfolio_item) { create(:portfolio_item) }
  let(:order_item) { create(:order_item, :portfolio_item => portfolio_item) }
  let(:subject) { described_class.new(order_item) }

  before do
    allow(Insights::API::Common::Request).to receive(:current_forwardable).and_return(default_headers)
  end

  around do |example|
    with_modified_env(:CATALOG_INVENTORY_URL => "http://inventory.example.com") do
      example.call
    end
  end

  describe "#process" do
    let(:api) { instance_double(CatalogInventoryApiClient::ServiceOfferingApi) }
    let(:tags) { [CatalogInventoryApiClient::Tag.new(:tag => "/x/y=z")] }

    before do
      allow(CatalogInventory::Service).to receive(:call).and_yield(api)
      allow(api).to receive(:applied_inventories_tags_for_service_offering).and_return(tags)
    end

    it "stores tag names, namespaces and values in a specific object format" do
      expect(subject.process.tag_resources).to eq(
        [
          {
            :app_name    => "catalog-inventory",
            :object_type => "ServiceInventory",
            :tags        => [
              {:tag => "/x/y=z"}
            ]
          }
        ]
      )
    end
  end
end
