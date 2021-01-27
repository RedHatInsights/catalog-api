describe Tags::CatalogInventory::RemoteInventory, :type => :service do
  let(:subject) { described_class.new(task) }

  before do
    allow(Insights::API::Common::Request).to receive(:current_forwardable).and_return(default_headers)
  end

  around do |example|
    with_modified_env(:CATALOG_INVENTORY_URL => "http://inventory.example.com") do
      example.call
    end
  end

  describe "#process" do
    let(:task) { CatalogInventoryApiClient::Task.new(:input => {:applied_inventories => ["1", "2"]}) }
    let(:tags_collection1) { CatalogInventoryApiClient::TagsCollection.new(:data => [tag1, tag2]) }
    let(:tag1) { CatalogInventoryApiClient::Tag.new(:tag => "/tag1namespace/tag1=tag1value") }
    let(:tag2) { CatalogInventoryApiClient::Tag.new(:tag => "/tag2namespace/tag2=tag2value") }

    let(:tags_collection2) { CatalogInventoryApiClient::TagsCollection.new(:data => [tag3, tag4]) }
    let(:tag3) { CatalogInventoryApiClient::Tag.new(:tag => "/tag3namespace/tag3=tag3value") }
    let(:tag4) { CatalogInventoryApiClient::Tag.new(:tag => "/tag4namespace/tag4=tag4value") }

    before do
      stub_request(:get, catalog_inventory_url("service_inventories/1/tags")).to_return(
        :status  => 200,
        :body    => tags_collection1.to_json,
        :headers => default_headers
      )
      stub_request(:get, catalog_inventory_url("service_inventories/2/tags")).to_return(
        :status  => 200,
        :body    => tags_collection2.to_json,
        :headers => default_headers
      )
    end

    it "stores tag names, namespaces and values in a specific object format" do
      expect(subject.process.tag_resources).to eq(
        [
          {
            :app_name    => "catalog-inventory",
            :object_type => "ServiceInventory",
            :tags        => [
              {:tag => "/tag1namespace/tag1=tag1value"},
              {:tag => "/tag2namespace/tag2=tag2value"}
            ]
          },
          {
            :app_name    => "catalog-inventory",
            :object_type => "ServiceInventory",
            :tags        => [
              {:tag => "/tag3namespace/tag3=tag3value"},
              {:tag => "/tag4namespace/tag4=tag4value"}
            ]
          }
        ]
      )
    end
  end
end
