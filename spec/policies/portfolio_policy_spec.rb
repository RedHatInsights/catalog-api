describe PortfolioPolicy do
  let(:portfolio) { create(:portfolio) }
  let(:user_context) { UserContext.new("current_request", "params", "controller_name") }
  let(:rbac_access) { instance_double(Catalog::RBAC::Access) }

  let(:subject) { described_class.new(user_context, portfolio) }

  before do
    allow(Catalog::RBAC::Access).to receive(:new).with(user_context).and_return(rbac_access)
  end

  describe "#create?" do
    context "when the create access check returns nil" do
      before do
        allow(rbac_access).to receive(:create_access_check).and_return(nil)
      end

      it "returns true" do
        expect(subject.create?).to eq(true)
      end
    end

    context "when the create access check throws an error" do
      before do
        allow(rbac_access).to receive(:create_access_check)
          .and_raise(Catalog::NotAuthorized, "Create access not authorized for Portfolio")
      end

      it "throws an error" do
        expect { subject.create? }.to raise_error(Catalog::NotAuthorized, /Create access not authorized for Portfolio/)
      end
    end
  end

  describe "#destroy?" do
    context "when the destroy access check returns nil" do
      before do
        allow(rbac_access).to receive(:destroy_access_check).and_return(nil)
      end

      it "returns true" do
        expect(subject.destroy?).to eq(true)
      end
    end

    context "when the destroy access check throws an error" do
      before do
        allow(rbac_access).to receive(:destroy_access_check)
          .and_raise(Catalog::NotAuthorized, "Destroy access not authorized for Portfolio")
      end

      it "throws an error" do
        expect { subject.destroy? }.to raise_error(Catalog::NotAuthorized, /Destroy access not authorized for Portfolio/)
      end
    end
  end

  describe "#show?" do
    context "when the show access check returns nil" do
      before do
        allow(rbac_access).to receive(:read_access_check).and_return(nil)
      end

      it "returns true" do
        expect(subject.show?).to eq(true)
      end
    end

    context "when the show access check throws an error" do
      before do
        allow(rbac_access).to receive(:read_access_check)
          .and_raise(Catalog::NotAuthorized, "Show access not authorized for Portfolio")
      end

      it "throws an error" do
        expect { subject.show? }.to raise_error(Catalog::NotAuthorized, /Show access not authorized for Portfolio/)
      end
    end
  end

  describe "#update?" do
    context "when the update access check returns nil" do
      before do
        allow(rbac_access).to receive(:update_access_check).and_return(nil)
      end

      it "returns true" do
        expect(subject.update?).to eq(true)
      end
    end

    context "when the update access check throws an error" do
      before do
        allow(rbac_access).to receive(:update_access_check)
          .and_raise(Catalog::NotAuthorized, "Update access not authorized for Portfolio")
      end

      it "throws an error" do
        expect { subject.update? }.to raise_error(Catalog::NotAuthorized, /Update access not authorized for Portfolio/)
      end
    end
  end

  describe "#copy?" do
    context "when all three rbac access checks returns nil" do
      before do
        allow(rbac_access).to receive(:resource_check).with('read', portfolio.id).and_return(nil)
        allow(rbac_access).to receive(:permission_check).with('create').and_return(nil)
        allow(rbac_access).to receive(:permission_check).with('update').and_return(nil)
      end

      it "returns true" do
        expect(subject.copy?).to eq(true)
      end
    end

    context "when any of the rbac access checks throw an error" do
      before do
        allow(rbac_access).to receive(:resource_check).with('read', portfolio.id).and_raise(Catalog::NotAuthorized, "Read access not authorized for Portfolio")
      end

      it "throws an error" do
        expect { subject.copy? }.to raise_error(Catalog::NotAuthorized, /Read access not authorized for Portfolio/)
      end
    end
  end

  describe "#share_or_unshare?" do
    before do
      allow(rbac_access).to receive(:admin_check).and_return(admin_check)
      allow(rbac_access).to receive(:group_check).and_return(group_check)
    end

    shared_examples "rbac combination is false" do
      it "returns false" do
        expect(subject.share_or_unshare?).to eq(false)
      end
    end

    context "when the admin check is true" do
      let(:admin_check) { true }

      context "when the group check is true" do
        let(:group_check) { true }

        it "returns true" do
          expect(subject.share_or_unshare?).to eq(true)
        end
      end

      context "when the group check is false" do
        let(:group_check) { false }

        it_behaves_like "rbac combination is false"
      end
    end

    context "when the admin check is false" do
      let(:admin_check) { false }

      context "when the group check is true" do
        let(:group_check) { true }

        it_behaves_like "rbac combination is false"
      end

      context "when the group check is false" do
        let(:group_check) { false }

        it_behaves_like "rbac combination is false"
      end
    end
  end
end
