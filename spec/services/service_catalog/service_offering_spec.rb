describe ServiceCatalog::ServiceOffering do
  let(:api_instance) { double }
  let(:service_offering) { described_class.new }
  let(:service_offering_ref) { "1" }
  let(:service_offering_source_ref) { "45" }
  let(:name) { 'test name' }
  let(:description) { 'test description' }
  let(:ivars) do
    [{:@name => name}, {:@description => description},
     {:@service_offering_ref => service_offering_ref},
     {:@service_offering_source_ref => service_offering_source_ref}]
  end
  let(:topology_service_offering) do
    TopologicalInventoryApiClient::ServiceOffering.new('name'        => name,
                                                       'id'          => service_offering_ref,
                                                       'description' => description,
                                                       'source_ref'  => '123',
                                                       'extra'       => {},
                                                       'source_id'   => service_offering_source_ref)
  end

  let(:ti_class) { class_double("TopologicalInventory").as_stubbed_const(:transfer_nested_constants => true) }

  before do
    allow(ti_class).to receive(:call).and_yield(api_instance)
  end

  it "#{described_class}#find" do
    expect(described_class).to receive(:new).and_return(service_offering)
    expect(api_instance).to receive(:show_service_offering).with(service_offering_ref).and_return(topology_service_offering)
    described_class.find(service_offering_ref)
  end

  it "#show" do
    expect(api_instance).to receive(:show_service_offering).with(service_offering_ref).and_return(topology_service_offering)
    service_offering.show(service_offering_ref)
  end

  it "#to_normalized_params" do
    ivars.each do |ivar|
      service_offering.instance_variable_set(ivar.first[0], ivar.first[1])
    end
    service_params = service_offering.to_normalized_params

    expect(service_params).to be_a Hash
    expect(service_params.count).to eql 4
    expect(service_params).to include(
      'name'                        => name,
      'description'                 => description,
      'service_offering_ref'        => service_offering_ref,
      'service_offering_source_ref' => service_offering_source_ref
    )
  end
end
