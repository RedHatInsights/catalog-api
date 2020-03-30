describe PortfolioItemPolicy::Scope, :type => [:service] do
  let(:user_context) { instance_double(UserContext, :group_uuids => ["123-456"]) }
  let(:scope) { PortfolioItem }
  let(:rbac_access) { instance_double(Catalog::RBAC::Access) }
  let(:subject) { described_class.new(user_context, scope) }

  describe "#resolve" do
    let(:portfolio) { create(:portfolio) }
    let!(:portfolio_item1) { create(:portfolio_item, :portfolio => portfolio) }
    let!(:portfolio_item2) { create(:portfolio_item) }

    around do |example|
      with_modified_env(:RBAC_URL => "http://rbac") do
        Insights::API::Common::Request.with_request(default_request) { example.call }
      end
    end

    before do
      allow(Insights::API::Common::RBAC::Roles).to receive(:assigned_role?).with("Catalog Administrator").and_return(admin?)
      allow(Catalog::RBAC::Access).to receive(:new).with(user_context, portfolio_item1).and_return(rbac_access)
    end

    context "when the user is a catalog administrator" do
      let(:admin?) { true }

      it "returns all of the portfolio items" do
        expect(subject.resolve).to contain_exactly(portfolio_item1, portfolio_item2)
      end
    end

    context "when the user is not a catalog administrator" do
      let(:admin?) { false }
      let(:rbac_aces) { instance_double(Catalog::RBAC::AccessControlEntries) }

      before do
        allow(Catalog::RBAC::AccessControlEntries).to receive(:new).with(["123-456"]).and_return(rbac_aces)
      end

      context "when the access control entries exist" do
        before do
          allow(rbac_aces).to receive(:ace_ids).with('read', Portfolio).and_return([portfolio.id])
        end

        it "returns the set limited by the correct portfolio ids" do
          expect(subject.resolve).to eq([portfolio_item1])
        end
      end

      context "when access control entries do not exist" do
        before do
          allow(rbac_aces).to receive(:ace_ids).with('read', Portfolio).and_return([])
        end

        it "returns an empty set" do
          expect(subject.resolve).to eq([])
        end
      end
    end
  end
end
