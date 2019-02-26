describe ServiceOffering::AddToPortfolioItem do
  include ServiceOfferingHelper
  let(:api_instance) { double }
  let(:service_offering_ref) { "1" }

  let(:add_to_portfolio_item) { described_class.new(:service_offering_ref => service_offering_ref) }

  let(:params) { HashWithIndifferentAccess.new(:name => "test name", :description => "test description") }

  let(:topology_service_offering) { fully_populated_service_offering }
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
    expect(item.attributes.count).to eql(18)

    # Does it have all the attributes transferred over that we set up above?
    # noinspection RubyResolve
    expect(item.attributes).to include(
      'name'                        => topology_service_offering.name,
      'description'                 => topology_service_offering.description,
      'service_offering_ref'        => service_offering_ref,
      'service_offering_source_ref' => topology_service_offering.source_id,
      'display_name'                => topology_service_offering.display_name,
      'long_description'            => topology_service_offering.long_description,
      'documentation_url'           => topology_service_offering.documentation_url,
      'support_url'                 => topology_service_offering.support_url,
      'distributor'                 => topology_service_offering.distributor
    )
  end

  context "private methods" do
    let(:service_offering) { build_service_offering(:name => "NameyMcNameFace") }

    before do
      add_to_portfolio_item.instance_variable_set("@service_offering", service_offering)
      add_to_portfolio_item.instance_variable_set("@params", params)
    end

    it "#{described_class}#creation_fields" do
      creation_fields = add_to_portfolio_item.send(:creation_fields)
      expect(creation_fields).to eq ["name"]
    end

    it "#{described_class}#generate_attributes" do

      my_params = add_to_portfolio_item.send(:generate_attributes)
      %w(name display_name).each do |name|
        expect(my_params[name]).to eq "NameyMcNameFace"
      end
    end

    it "#{described_class}#populate_missing_fields(params)" do
      my_params = add_to_portfolio_item.send(:populate_missing_fields)

      # It should have added the extra field (source ref) as well as inferring the values of long_description and display name, giving us 5 total fields.
      expect(my_params.keys.size).to eql 5
      expect(my_params[:long_description]).to eq(params[:description])
      expect(my_params[:display_name]).to eq(params[:name])
    end
  end
end
