describe Catalog::ProviderControlParameters, :type => :service do
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

  before do
    allow(ManageIQ::API::Common::Request).to receive(:current_forwardable).and_return(default_headers)
  end

  around do |example|
    with_modified_env(:TOPOLOGICAL_INVENTORY_URL => "http://localhost") do
      example.call
    end
  end

  describe "#process" do
    let(:container_project_response) do
      TopologicalInventoryApiClient::ContainerProjectsCollection.new(:data => [project2, project1])
    end

    before do
      stub_request(:get, "http://localhost/api/topological-inventory/v1.0/sources/1/container_projects")
        .to_return(:status => 200, :body => container_project_response.to_json, :headers => default_headers)
    end

    context "with a valid portfolio item" do
      let(:namespace_list) do
        data = provider_control_parameters.process.data
        data['properties']['namespace']['enum']
      end

      it 'sorts project list' do
        expect(namespace_list).to contain_exactly(project1_name, project2_name)
      end
    end

    context "with an invalid portfolio item" do
      let(:params) { 1 }
      it "raises exception" do
        expect { provider_control_parameters.process }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
