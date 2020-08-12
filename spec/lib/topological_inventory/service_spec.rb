describe TopologicalInventory::Service, :type => [:topology, :current_forwardable] do
  let(:topo_ex) { TopologicalInventoryApiClient::ApiError.new("kaboom") }

  it "raises TopologyError" do
    expect do
      described_class.call do |_api|
        raise topo_ex
      end
    end.to raise_exception(Catalog::TopologyError)
  end
end
