describe ServiceOffering do
  include ServiceSpecHelper

  let(:api_instance) { double(:api_instance, :show_service_offering => service_offering) }
  let(:service_offering) { ServiceOffering.new(params) }
  let(:params) { {'service_offering_ref' => '10'} }
  let(:ivars) do
    [{:@name => 'test name'}, {:@description => 'test description'},
     {:@service_offering_ref => '12'}, {:@params => {:blah => 'nah'}}]
  end

  before do
    with_modified_env TOPOLOGY_SERVICE_URL: 'http://www.example.com' do
      allow(service_offering).to receive(:api_instance).and_return(api_instance)
    end
  end

  it "#{described_class}#find" do
    expect(described_class).to receive(:new).with({}).and_return(service_offering)
    ServiceOffering.find(1)
  end

  it "#show" do
    expect(api_instance).to receive(:show_service_offering).with('10')
    service_offering.show('10')
  end

  it "#to_normalized_params" do
    ivars.each do |ivar|
      service_offering.instance_variable_set(ivar.first[0], ivar.first[1])
    end
    service_params = service_offering.to_normalized_params

    expect(service_params).to be_a Hash
    expect(service_params.count).to eql 3
    expect(service_params).to include(
      'name'                  => 'test name',
      'description'           => 'test description',
      'service_offering_ref'  => '12'
    )
    expect(service_params).to_not include(
      'params' => {:blah => 'nah'}
    )
  end
end
