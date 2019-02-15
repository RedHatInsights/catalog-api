describe ServiceOffering::AddToPortfolioItem do
  let(:api_instance) { double }
  let(:service_offering_ref) { "1" }

  let(:add_to_portfolio_item) { described_class.new(:service_offering_ref => service_offering_ref) }

  let(:params) { HashWithIndifferentAccess.new(:name => "test name", :description => "test description") }

  let(:topology_service_offering) { ServiceOfferingHelper.fully_populated_service_offering }
  let(:topological_inventory) do
    class_double("TopologicalInventory")
      .as_stubbed_const(:transfer_nested_constants => true)
  end

  before do
    allow(topological_inventory).to receive(:call).and_yield(api_instance)
  end

  it "#{described_class}#process" do
    expect(api_instance).to receive(:show_service_offering).with(service_offering_ref).and_return(topology_service_offering)

    item = add_to_portfolio_item.process.item

    expect(item).to be_a(PortfolioItem)
    expect(item.attributes.count).to eql(17)

    # Does it have all the attributes transferred over that we set up above?
    # noinspection RubyResolve
    expect(item.attributes).to include(
      'name'                        => topology_service_offering.name,
      'description'                 => topology_service_offering.description,
      'service_offering_ref'        => service_offering_ref,
      'service_offering_source_ref' => topology_service_offering.source_ref,
      'display_name'                => topology_service_offering.display_name,
      'long_description'            => topology_service_offering.long_description,
      'documentation_url'           => topology_service_offering.documentation_url,
      'support_url'                 => topology_service_offering.support_url,
      'distributor'                 => topology_service_offering.distributor
    )
  end

  it "#{described_class}#populate_missing_fields(params)" do
    # Send in params which only has 2 fields
    add_to_portfolio_item.instance_variable_set("@params", params)
    my_params = add_to_portfolio_item.send(:populate_missing_fields)

    # It should have added the extra field (source ref) as well as inferring the values of long_description and display name, giving us 5 total fields.
    expect(my_params.keys.size).to eql 5
    expect(my_params[:long_description]).to eq(params[:description])
    expect(my_params[:display_name]).to eq(params[:name])
  end

  it "#{described_class}#determine_valid_fields" do
    add_to_portfolio_item.instance_variable_set("@service_offering", topology_service_offering)

    expect(topology_service_offering.instance_variables.count).to eql 10
    filtered = add_to_portfolio_item.send(:determine_valid_fields)
    expect(filtered.count).to eql 9
  end

  it "#{described_class}#create_param_map(params)" do
    service_offering = ServiceOfferingHelper.build_service_offering(:name => "NameyMcNameFace")
    add_to_portfolio_item.instance_variable_set("@service_offering", service_offering)

    param_map = add_to_portfolio_item.send(:create_param_map, add_to_portfolio_item.send(:determine_valid_fields))
    # Only expected one is name since that's what we added.
    expect(param_map.count).to eql 1
  end
end
