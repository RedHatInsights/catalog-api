describe Catalog::ProviderControlParameters do
  let(:api_instance) { double }
  let(:provider_control) { described_class.new }
  let(:name) { 'project1' }
  let(:description) { 'test description' }
  let(:source_id) { "1" }
  let(:params) { portfolio_item.id }
  let(:provider_control_parameters) { described_class.new(params) }
  let(:portfolio_item) { create(:portfolio_item, :service_offering_source_ref => source_id) }
  let(:project1) do
    TopologicalInventoryApiClient::ContainerProject.new('name'      => "project one",
                                                        'source_id' => "1")
  end
  let(:project2) do
    TopologicalInventoryApiClient::ContainerProject.new('name'      => "project one",
                                                        'source_id' => "2")
  end

  let(:ti_class) { class_double("TopologicalInventory").as_stubbed_const(:transfer_nested_constants => true) }

  before do
    allow(ti_class).to receive(:call).and_yield(api_instance)
  end

  it "#{described_class}#process" do
    result = double('links' => {}, 'meta' => {}, 'data' => [project1, project2])
    expect(api_instance).to receive(:list_source_container_projects).and_return(result)

    data = provider_control_parameters.process.data
    expect(data['properties']['namespace']['enum'].first).to eq("project one")
  end

  context "invalid portfolio item" do
    let(:params) { 1 }
    it "raises exception" do
      expect { provider_control_parameters.process }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
