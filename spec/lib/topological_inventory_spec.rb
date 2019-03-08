describe TopologicalInventory do
  let(:topo_ex) { TopologicalInventoryApiClient::ApiError.new("kaboom") }

  it "raises TopologyError" do
    with_modified_env :TOPOLOGICAL_INVENTORY_URL => 'http://www.example.com' do
      allow(ManageIQ::API::Common::Request).to receive(:current_forwardable).and_return(:x => 1)
      expect do
        described_class.call do |_api|
          raise topo_ex
        end
      end.to raise_exception(Catalog::TopologyError)
    end
  end
end
