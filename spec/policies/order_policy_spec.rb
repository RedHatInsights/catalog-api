describe OrderPolicy do
  let(:order) { create(:order) }
  let(:user_context) { UserContext.new("current_request", "params", "controller_name") }

  let(:subject) { described_class.new(user_context, order) }

  describe "#show?" do
    let(:rbac_access) { instance_double(Catalog::RBAC::Access) }

    before do
      allow(Catalog::RBAC::Access).to receive(:new).with(user_context).and_return(rbac_access)
    end

    it "delegates to the rbac access" do
      expect(rbac_access).to receive(:read_access_check).and_return(true)
      expect(subject.show?).to eq(true)
    end
  end

  describe "#submit_order?" do
    let(:service_offering) { instance_double(Catalog::ServiceOffering, :archived => archived) }

    before do
      allow(Catalog::ServiceOffering).to receive(:new).with(order).and_return(service_offering)
      allow(service_offering).to receive(:process).and_return(service_offering)
    end

    context "when the service offering is archived" do
      let(:archived) { true }

      it "raises an error" do
        expect { subject.submit_order? }.to raise_error(Catalog::ServiceOfferingArchived, /has been archived/)
      end
    end

    context "when the service offering is not archived" do
      let(:archived) { false }

      it "returns true" do
        expect(subject.submit_order?).to eq(true)
      end
    end
  end
end
