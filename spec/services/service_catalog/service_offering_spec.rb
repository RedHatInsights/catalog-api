describe ServiceCatalog::ServiceOffering do
  include ServiceSpecHelper

  let(:api_instance) { double }
  let(:service_offering) { described_class.new }
  let(:service_offering_ref) { "1" }
  let(:name) { 'test name' }
  let(:description) { 'test description' }
  let(:ivars) do
    [{:@name => name}, {:@description => description},
     {:@service_offering_ref => service_offering_ref}]
  end

  it "#{described_class}#find" do
    expect(described_class).to receive(:new).and_return(service_offering)
    described_class.find(service_offering_ref)
  end

  it "#show" do
    expect(service_offering.show(service_offering_ref)).to be_a ServiceCatalog::ServiceOffering
  end

  it "#to_normalized_params" do
    ivars.each do |ivar|
      service_offering.instance_variable_set(ivar.first[0], ivar.first[1])
    end
    service_params = service_offering.to_normalized_params

    expect(service_params).to be_a Hash
    expect(service_params.count).to eql 3
    expect(service_params).to include(
      'name'                 => name,
      'description'          => description,
      'service_offering_ref' => service_offering_ref
    )
  end
end
