describe Catalog::ProviderControlParameters do
  let(:api_instance) { double }
  let(:provider_control) { described_class.new }
  let(:name) { 'project1' }
  let(:description) { 'test description' }
  let(:source_id) { "1" }
  let(:params) { portfolio_item.id }
  let(:provider_control_parameters) { described_class.new(params) }
  let(:portfolio_item) { create(:portfolio_item, :service_offering_source_ref => source_id) }
  let(:project1_name) { 'project-one' }
  let(:project2_name) { 'project-two' }
  let(:project1) do
    TopologicalInventoryApiClient::ContainerProject.new('name'      => project1_name,
                                                        'source_id' => "1")
  end
  let(:project2) do
    TopologicalInventoryApiClient::ContainerProject.new('name'      => project2_name,
                                                        'source_id' => "2")
  end
  let(:ti_class) { class_double("TopologicalInventory").as_stubbed_const(:transfer_nested_constants => true) }

  context "#{described_class}#process" do
    before do
      allow(ti_class).to receive(:call).and_yield(api_instance)

      container_projects = double('links' => {}, 'meta' => {}, 'data' => [project2, project1])
      expect(api_instance).to receive(:list_source_container_projects).and_return(container_projects)
    end

    let(:namespace_list) do
      data = provider_control_parameters.process.data
      data['properties']['namespace']['enum']
    end

    it 'sorts project list' do
      expect(namespace_list).to contain_exactly(project1_name, project2_name)
    end
  end

  context "invalid portfolio item" do
    let(:params) { 1 }
    it "raises exception" do
      expect { provider_control_parameters.process }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
