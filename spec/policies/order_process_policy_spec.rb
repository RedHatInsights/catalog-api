describe OrderProcessPolicy do
  let(:order_process) { create(:order_process) }
  let(:user_context) { UserContext.new("current_request", "params") }
  let(:rbac_access) { instance_double(Catalog::RBAC::Access) }

  let(:subject) { described_class.new(user_context, order_process) }

  before do
    allow(Catalog::RBAC::Access).to receive(:new).with(user_context, order_process).and_return(rbac_access)
  end

  describe "#show?" do
    it "returns true" do
      expect(rbac_access).to receive(:read_access_check).and_return(true)
      expect(subject.show?).to eq(true)
    end
  end

  describe "#create?" do
    it "returns true" do
      expect(rbac_access).to receive(:create_access_check).with(OrderProcess).and_return(true)
      expect(subject.create?).to eq(true)
    end
  end

  describe "#link?" do
    it "returns true" do
      expect(rbac_access).to receive(:link_access_check).and_return(true)
      expect(subject.link?).to eq(true)
    end
  end

  describe "#unlink?" do
    it "returns true" do
      expect(rbac_access).to receive(:unlink_access_check).and_return(true)
      expect(subject.unlink?).to eq(true)
    end
  end

  describe "#update?" do
    it "returns true" do
      expect(rbac_access).to receive(:update_access_check).and_return(true)
      expect(subject.update?).to eq(true)
    end
  end

  describe "#destroy?" do
    it "returns true" do
      expect(rbac_access).to receive(:destroy_access_check).and_return(true)
      expect(subject.destroy?).to eq(true)
    end
  end

  describe "#user_capabilities" do
    before do
      allow(rbac_access).to receive(:read_access_check).and_return(true)
      allow(rbac_access).to receive(:create_access_check).with(OrderProcess).and_return(true)
      allow(rbac_access).to receive(:destroy_access_check).and_return(true)
      allow(rbac_access).to receive(:update_access_check).and_return(true)
      allow(rbac_access).to receive(:link_access_check).and_return(true)
      allow(rbac_access).to receive(:unlink_access_check).and_return(true)
    end

    it "returns user capabilities" do
      expect(subject.user_capabilities).to eq(
        "create"  => true,
        "destroy" => true,
        "link"    => true,
        "show"    => true,
        "unlink"  => true,
        "update"  => true
      )
    end
  end
end
