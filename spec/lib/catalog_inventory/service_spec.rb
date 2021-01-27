describe CatalogInventory::Service, :type => [:inventory, :current_forwardable] do
  let(:topo_ex) { CatalogInventoryApiClient::ApiError.new("kaboom") }

  it "raises TopologyError" do
    expect do
      described_class.call(CatalogInventoryApiClient::DefaultApi) do |_api|
        raise topo_ex
      end
    end.to raise_exception(Catalog::CatalogInventoryError)
  end
end
