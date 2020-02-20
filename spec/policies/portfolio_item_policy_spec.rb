describe PortfolioItemPolicy do
  let(:portfolio_item) { create(:portfolio_item, :portfolio => portfolio) }
  let(:portfolio) { create(:portfolio) }
  let(:user_context) { UserContext.new("current_request", "params", "controller_name") }
  let(:rbac_access) { instance_double(Catalog::RBAC::Access) }

  subject { described_class.new(user_context, portfolio_item) }

  before do
    allow(Catalog::RBAC::Access).to receive(:new).with(user_context).and_return(rbac_access)
  end

  describe "#index?" do
    it "delegates to the rbac access permission check on portfolios" do
      expect(rbac_access).to receive(:permission_check).with('read', Portfolio).and_return(true)
      expect(subject.index?).to eq(true)
    end
  end

  describe "#create?" do
    subject { described_class.new(user_context, portfolio) }

    it "delegates to the rbac access create check" do
      expect(rbac_access).to receive(:resource_check).with('update', portfolio.id, Portfolio).and_return(true)
      expect(subject.create?).to eq(true)
    end
  end

  describe "#update?" do
    it "delegates to the rbac access update check" do
      expect(rbac_access).to receive(:update_access_check).and_return(true)
      expect(subject.update?).to eq(true)
    end
  end

  describe "#destroy?" do
    it "delegates to the rbac access destroy check" do
      expect(rbac_access).to receive(:destroy_access_check).and_return(true)
      expect(subject.destroy?).to eq(true)
    end
  end

  describe "#copy?" do
    let(:copy_read_check) { true }
    let(:copy_create_check) { true }
    let(:copy_update_check) { true }

    before do
      allow(rbac_access).to receive(:resource_check).with('read', portfolio_item.id).and_return(copy_read_check)
      allow(rbac_access).to receive(:permission_check).with('create', Portfolio).and_return(copy_create_check)
      allow(rbac_access).to receive(:permission_check).with('update', Portfolio).and_return(copy_update_check)
    end

    context "when the rbac access check is false on the portfolio item read" do
      let(:copy_read_check) { false }

      it "returns false" do
        expect(subject.copy?).to eq(false)
      end
    end

    context "when the rbac access create check is false" do
      let(:copy_create_check) { false }

      it "returns false" do
        expect(subject.copy?).to eq(false)
      end
    end

    context "when the rbac access update check is false" do
      let(:copy_update_check) { false }

      it "returns false" do
        expect(subject.copy?).to eq(false)
      end
    end

    context "when all three rbac access checks return true" do
      it "returns true" do
        expect(subject.copy?).to eq(true)
      end
    end
  end
end
