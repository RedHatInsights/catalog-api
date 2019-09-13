describe ServiceOffering::AddToPortfolioItem, :type => :service do
  include ServiceOfferingHelper
  let(:api_instance) { double }
  let(:service_offering_ref) { "1" }
  let(:user_defined_name) { "Frank" }
  let(:user_defined_description) { "Franks Description" }
  let(:topo_ex) { Catalog::TopologyError.new("kaboom") }
  let(:subject) { described_class.new(params) }

  let(:params) { HashWithIndifferentAccess.new(:name => user_defined_name, :description => user_defined_description, :service_offering_ref => service_offering_ref) }

  let(:topology_service_offering) { fully_populated_service_offering }
  let(:service_offering_icon) { fully_populated_service_offering_icon }
  let(:topological_inventory) do
    class_double("TopologicalInventory")
      .as_stubbed_const(:transfer_nested_constants => true)
  end
  let(:validater) { instance_double(Catalog::ValidateSource) }
  let(:valid_source) { true }

  before do
    allow(topological_inventory).to receive(:call).and_yield(api_instance)
    allow(api_instance).to receive(:show_service_offering).with(service_offering_ref).and_return(topology_service_offering)
    allow(api_instance).to receive(:show_service_offering_icon).with(topology_service_offering.service_offering_icon_id).and_return(service_offering_icon)
    allow(Catalog::ValidateSource).to receive(:new).with(topology_service_offering.source_id).and_return(validater)
    allow(validater).to receive(:process).and_return(validater)
    allow(validater).to receive(:valid).and_return(valid_source)
  end

  context "user provided params" do
    it "#process" do
      ManageIQ::API::Common::Request.with_request(default_request) do
        result = subject.process
        expect(result.item.name).to eq(user_defined_name)
        expect(result.item.description).to eq(user_defined_description)
      end
    end

    context "when service_offering does not have a long_description" do
      let(:topology_service_offering) { fully_populated_service_offering.tap { |so| so.long_description = nil } }

      it "should leave long_description set to nil" do
        ManageIQ::API::Common::Request.with_request(default_request) do
          result = subject.process
          expect(result.item.long_description).to be_nil
        end
      end
    end
  end

  context "no user provided params" do
    let(:params) { HashWithIndifferentAccess.new(:service_offering_ref => service_offering_ref) }
    it "#process" do
      ManageIQ::API::Common::Request.with_request(default_request) do
        result = subject.process
        expect(result.item.name).to eq("test name")
        expect(result.item.description).to eq("test description")

        expect(result.item.icons.first.source_id).to eq service_offering_icon.source_id
        expect(result.item.icons.first.source_ref).to eq service_offering_icon.source_ref
      end
    end
  end

  context "when there is no icon" do
    let(:topology_service_offering)  { fully_populated_service_offering.tap { |so| so.service_offering_icon_id = nil } }

    it "does not copy over the icon" do
      ManageIQ::API::Common::Request.with_request(default_request) do
        result = subject.process
        expect(result.item.icons.count).to eq 0
      end
    end
  end

  context 'when the icon has no data' do
    let(:service_offering_icon) { fully_populated_service_offering_icon.tap { |icon| icon.data = nil } }

    it "does not copy over the icon" do
      ManageIQ::API::Common::Request.with_request(default_request) do
        result = subject.process
        expect(result.item.icons.count).to eq 0
      end
    end
  end

  context "raises an error" do
    let(:params) { HashWithIndifferentAccess.new(:service_offering_ref => service_offering_ref) }
    it "#process" do
      allow(topological_inventory).to receive(:call).and_raise(topo_ex)
      ManageIQ::API::Common::Request.with_request(default_request) do
        expect { subject.process }.to raise_exception(Catalog::TopologyError)
      end
    end
  end

  context "when the source is invalid" do
    let(:valid_source) { false }

    it "should raise unauthorized" do
      ManageIQ::API::Common::Request.with_request(default_request) do
        expect { subject.process }.to raise_exception(Catalog::NotAuthorized)
      end
    end
  end
end
