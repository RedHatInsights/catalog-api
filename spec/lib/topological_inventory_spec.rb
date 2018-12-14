describe TopologicalInventory do
  include ServiceSpecHelper
  let(:topo_ex) { TopologicalInventoryApiClient::ApiError.new("kaboom") }

  it "raises TopologyError" do
    with_modified_env :TOPOLOGICAL_INVENTORY_URL => 'http://www.example.com' do
      expect do
        described_class.call do |_api|
          raise topo_ex
        end
      end.to raise_exception(ServiceCatalog::TopologyError)
    end
  end
end
