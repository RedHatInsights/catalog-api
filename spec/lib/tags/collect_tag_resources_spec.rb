describe Tags::CollectTagResources do
  let(:order) { create(:order) }
  let(:task) { CatalogInventoryApiClient::Task.new }
  let(:subject) { described_class.new(task, order) }

  context "#process" do
    let(:tag_resources) do
      [{:app_name    => 'catalog',
        :object_type => 'PortfolioItem',
        :tags        => [{:tag => "/Charkie/Gnocchi=Hundley"}]},
       {:app_name    => 'catalog',
        :object_type => 'Portfolio',
        :tags        => [{:tag => "/Compass/Curious George=Jumpy Squirrel"}]}]
    end
    let(:local_tag_resources) do
      [{:app_name    => 'catalog',
        :object_type => 'PortfolioItem',
        :tags        => [{:tag => "/Charkie/Gnocchi=Hundley"}]}]
    end
    let(:remote_tag_resources) do
      [{:app_name    => 'catalog',
        :object_type => 'Portfolio',
        :tags        => [{:tag => "/Compass/Curious George=Jumpy Squirrel"}]}]
    end

    let(:inventory_instance) { instance_double(Tags::CatalogInventory::RemoteInventory) }
    let(:resource_instance) { instance_double(Tags::CollectLocalOrderResources) }
    before do
      allow(Tags::CatalogInventory::RemoteInventory).to receive(:new).and_return(inventory_instance)
      allow(inventory_instance).to receive(:process).and_return(inventory_instance)
      allow(inventory_instance).to receive(:tag_resources).and_return(remote_tag_resources)
      allow(Tags::CollectLocalOrderResources).to receive(:new).and_return(resource_instance)
      allow(resource_instance).to receive(:process).and_return(resource_instance)
      allow(resource_instance).to receive(:tag_resources).and_return(local_tag_resources)
    end

    it "logs a message about tag resources" do
      expect(Rails.logger).to receive(:info).with("Tag resources for order #{order.id}: #{tag_resources}")
      subject.process
    end

    it "returns tag resources" do
      expect(subject.process.tag_resources).to eq(tag_resources)
    end
  end
end
