describe PortfolioPolicy do
  let(:portfolio) { create(:portfolio) }
  let(:user_context) { UserContext.new("current_request", "params", "controller_name") }
  let(:rbac_access) { instance_double(Catalog::RBAC::Access) }

  let(:subject) { described_class.new(user_context, portfolio) }

  before do
    allow(Catalog::RBAC::Access).to receive(:new).with(user_context).and_return(rbac_access)
  end

  describe "#create?" do
    it "delegates to the rbac access create check" do
      expect(rbac_access).to receive(:create_access_check).and_return(true)
      expect(subject.create?).to eq(true)
    end
  end

  describe "#destroy?" do
    it "delegates to the rbac access destroy check" do
      expect(rbac_access).to receive(:destroy_access_check).and_return(true)
      expect(subject.destroy?).to eq(true)
    end
  end

  describe "#show?" do
    it "delegates to the rbac access read check" do
      expect(rbac_access).to receive(:read_access_check).and_return(true)
      expect(subject.show?).to eq(true)
    end
  end

  describe "#update?" do
    it "delegates to the rbac access update check" do
      expect(rbac_access).to receive(:update_access_check).and_return(true)
      expect(subject.update?).to eq(true)
    end
  end

  describe "#copy?" do
    let(:copy_read_check) { true }
    let(:copy_create_check) { true }
    let(:copy_update_check) { true }

    before do
      allow(rbac_access).to receive(:resource_check).with('read', portfolio.id).and_return(copy_read_check)
      allow(rbac_access).to receive(:create_access_check).and_return(copy_create_check)
      allow(rbac_access).to receive(:resource_check).with('update', portfolio.id).and_return(copy_update_check)
    end

    context "when the rbac access check is false on the portfolio read" do
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

  [:share?, :unshare?].each do |method|
    describe "##{method}" do
      before do
        allow(rbac_access).to receive(:admin_check).and_return(admin_check)
      end

      context "when the admin check is true" do
        let(:admin_check) { true }

        it "returns true" do
          expect(subject.send(method)).to eq(true)
        end
      end

      context "when the admin check is false" do
        let(:admin_check) { false }

        it "returns false" do
          expect(subject.send(method)).to eq(false)
        end
      end
    end
  end
end
