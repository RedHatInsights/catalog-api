describe PortfolioPolicy do
  let(:portfolio) { create(:portfolio) }
  let(:user_context) { UserContext.new("current_request", "params") }
  let(:rbac_access) { instance_double(Catalog::RBAC::Access) }

  let(:subject) { described_class.new(user_context, portfolio) }

  before do
    allow(Catalog::RBAC::Access).to receive(:new).with(user_context, portfolio).and_return(rbac_access)
  end

  shared_examples "a policy action that requires create access" do |method|
    it "delegates to the rbac access create check" do
      expect(rbac_access).to receive(:create_access_check).and_return(true)
      expect(subject.send(method)).to eq(true)
    end
  end

  describe "#show?" do
    it "delegates to the rbac access read check" do
      expect(rbac_access).to receive(:read_access_check).and_return(true)
      expect(subject.show?).to eq(true)
    end
  end

  describe "#set_approval?" do
    let(:update_access_check) { true }
    let(:approval_workflow_check) { true }

    before do
      allow(rbac_access).to receive(:update_access_check).and_return(update_access_check)
      allow(rbac_access).to receive(:approval_workflow_check).and_return(approval_workflow_check)
    end

    context "when the update check is false" do
      let(:update_access_check) { false }

      it "returns false" do
        expect(subject.set_approval?).to eq(false)
      end
    end

    context "when the approval workflow check is false" do
      let(:approval_workflow_check) { false }

      it "returns false" do
        expect(subject.set_approval?).to eq(false)
      end
    end

    context "when the update check and the approval workflow check are true" do
      it "returns true" do
        expect(subject.set_approval?).to eq(true)
      end
    end
  end

  %i[destroy? restore?].each do |method|
    describe "##{method}" do
      it "delegates to the rbac access destroy check" do
        expect(rbac_access).to receive(:destroy_access_check).and_return(true)
        expect(subject.send(method)).to eq(true)
      end
    end
  end

  [:create?, :copy?].each do |method|
    describe "##{method}" do
      it_behaves_like "a policy action that requires create access", method
    end
  end

  describe "#update?" do
    it "delegates to the rbac access update check" do
      expect(rbac_access).to receive(:update_access_check).and_return(true)
      expect(subject.update?).to eq(true)
    end
  end

  [:share?, :unshare?].each do |method|
    describe "##{method}" do
      it "delegates to the rbac access update check" do
        expect(rbac_access).to receive(:admin_access_check).with("portfolios", "update").and_return(true)
        expect(subject.send(method)).to eq(true)
      end
    end
  end

  describe "#user_capabilities" do
    before do
      allow(rbac_access).to receive(:read_access_check).and_return(true)
      allow(rbac_access).to receive(:create_access_check).and_return(true)
      allow(rbac_access).to receive(:destroy_access_check).and_return(true)
      allow(rbac_access).to receive(:update_access_check).and_return(true)
      allow(rbac_access).to receive(:admin_access_check).with("portfolios", "update").and_return(true)
      allow(rbac_access).to receive(:approval_workflow_check).and_return(true)
    end

    it "returns a hash of user capabilities" do
      expect(subject.user_capabilities).to eq({
        "create"       => true,
        "update"       => true,
        "destroy"      => true,
        "restore"      => true,
        "copy"         => true,
        "share"        => true,
        "unshare"      => true,
        "show"         => true,
        "set_approval" => true
      })
    end
  end
end
