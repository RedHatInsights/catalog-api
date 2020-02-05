describe PortfolioItemPolicy do
  let(:portfolio_item) { create(:portfolio_item) }
  let(:user_context) { UserContext.new("current_request", "params", "controller_name") }
  let(:rbac_access) { instance_double(Catalog::RBACAccess) }

  let(:subject) { described_class.new(user_context, portfolio_item) }

  before do
    allow(Catalog::RBACAccess).to receive(:new).with(user_context).and_return(rbac_access)
  end

  describe "#create?" do
    context "when the policy access returns nil" do
      before do
        allow(rbac_access).to receive(:create_access_check).and_return(nil)
      end

      it "returns true" do
        expect(subject.create?).to eq(true)
      end
    end

    context "when the policy access throws an error" do
      before do
        allow(rbac_access).to receive(:create_access_check).and_raise(Catalog::NotAuthorized, "Create access not authorized for PortfolioItem")
      end

      it "throws an error" do
        expect { subject.create? }.to raise_error(Catalog::NotAuthorized, /Create access not authorized for PortfolioItem/)
      end
    end
  end

  describe "#update?" do
    context "when the policy access returns nil" do
      before do
        allow(rbac_access).to receive(:update_access_check).and_return(nil)
      end

      it "returns true" do
        expect(subject.update?).to eq(true)
      end
    end

    context "when the policy access throws an error" do
      before do
        allow(rbac_access).to receive(:update_access_check).and_raise(Catalog::NotAuthorized, "Update access not authorized for PortfolioItem")
      end

      it "throws an error" do
        expect { subject.update? }.to raise_error(Catalog::NotAuthorized, /Update access not authorized for PortfolioItem/)
      end
    end
  end

  describe "#destroy?" do
    context "when the policy access returns nil" do
      before do
        allow(rbac_access).to receive(:destroy_access_check).and_return(nil)
      end

      it "returns true" do
        expect(subject.destroy?).to eq(true)
      end
    end

    context "when the policy access throws an error" do
      before do
        allow(rbac_access).to receive(:destroy_access_check).and_raise(Catalog::NotAuthorized, "Delete access not authorized for PortfolioItem")
      end

      it "throws an error" do
        expect { subject.destroy? }.to raise_error(Catalog::NotAuthorized, /Delete access not authorized for PortfolioItem/)
      end
    end
  end

  describe "#copy?" do
    context "when all three policy access checks returns nil" do
      before do
        allow(rbac_access).to receive(:resource_check).with('read', portfolio_item.id).and_return(nil)
        allow(rbac_access).to receive(:permission_check).with('create', Portfolio).and_return(nil)
        allow(rbac_access).to receive(:permission_check).with('update', Portfolio).and_return(nil)
      end

      it "returns true" do
        expect(subject.copy?).to eq(true)
      end
    end

    context "when any of the policy access checks throw an error" do
      before do
        allow(rbac_access).to receive(:resource_check).with('read', portfolio_item.id).and_raise(Catalog::NotAuthorized, "Read access not authorized for PortfolioItem")
      end

      it "throws an error" do
        expect { subject.copy? }.to raise_error(Catalog::NotAuthorized, /Read access not authorized for PortfolioItem/)
      end
    end
  end
end
