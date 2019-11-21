describe Tags::Topology::RemoteInventory, :type => :service do
  let(:subject) { described_class.new(task) }

  before do
    allow(Insights::API::Common::Request).to receive(:current_forwardable).and_return(default_headers)
  end

  around do |example|
    with_modified_env(:TOPOLOGICAL_INVENTORY_URL => "http://localhost") do
      example.call
    end
  end

  describe "#process" do
    let(:task) { TopologicalInventoryApiClient::Task.new(:context => {:applied_inventories => ["1", "2"]}) }
    let(:tags_collection1) { TopologicalInventoryApiClient::TagsCollection.new(:data => [tag1, tag2]) }
    let(:tag1) { TopologicalInventoryApiClient::Tag.new(:name => "tag1", :namespace => "tag1namespace", :value => "tag1value", :description => "tag1description") }
    let(:tag2) { TopologicalInventoryApiClient::Tag.new(:name => "tag2", :namespace => "tag2namespace", :value => "tag2value") }

    let(:tags_collection2) { TopologicalInventoryApiClient::TagsCollection.new(:data => [tag3, tag4]) }
    let(:tag3) { TopologicalInventoryApiClient::Tag.new(:name => "tag3", :namespace => "tag3namespace", :value => "tag3value") }
    let(:tag4) { TopologicalInventoryApiClient::Tag.new(:name => "tag4", :namespace => "tag4namespace", :value => "tag4value") }

    before do
      stub_request(:get, "http://localhost/api/topological-inventory/v1.0/service_inventories/1/tags").to_return(
        :status  => 200,
        :body    => tags_collection1.to_json,
        :headers => default_headers
      )
      stub_request(:get, "http://localhost/api/topological-inventory/v1.0/service_inventories/2/tags").to_return(
        :status  => 200,
        :body    => tags_collection2.to_json,
        :headers => default_headers
      )
    end

    it "stores tag names, namespaces and values in a specific object format" do
      expect(subject.process.tag_resources).to eq(
        [
          {
            :app_name    => "topology",
            :object_type => "ServiceInventory",
            :tags        => [
              {:name => "tag1", :namespace => "tag1namespace", :value => "tag1value"},
              {:name => "tag2", :namespace => "tag2namespace", :value => "tag2value"}
            ]
          },
          {
            :app_name    => "topology",
            :object_type => "ServiceInventory",
            :tags        => [
              {:name => "tag3", :namespace => "tag3namespace", :value => "tag3value"},
              {:name => "tag4", :namespace => "tag4namespace", :value => "tag4value"}
            ]
          }
        ]
      )
    end
  end
end
