describe ApplicationPolicy::Scope, :type => [:service] do
  let(:user_context) { instance_double(UserContext, :group_uuids => ["123-456"], :access => catalog_access) }
  let(:catalog_access) { instance_double(Insights::API::Common::RBAC::Access, :scopes => scopes) }
  let(:scope) { Portfolio }
  let(:rbac_access) { instance_double(Catalog::RBAC::Access) }
  let(:subject) { described_class.new(user_context, scope) }

  describe "#resolve" do
    let(:portfolio) { create(:portfolio) }

    before do
      allow(Catalog::RBAC::Access).to receive(:new).with(user_context, portfolio).and_return(rbac_access)
    end

    context "when the user is in the admin scope" do
      let(:scopes) { %w[admin group user] }

      it "returns all of the requested objects" do
        expect(subject.resolve).to contain_exactly(portfolio)
      end
    end

    context "when the user is in the group scope" do
      let(:scopes) { %w[group user] }
      let(:rbac_aces) { instance_double(Catalog::RBAC::AccessControlEntries) }

      before do
        allow(Catalog::RBAC::AccessControlEntries).to receive(:new).with(["123-456"]).and_return(rbac_aces)
      end

      context "when the access control entries exist" do
        before do
          allow(rbac_aces).to receive(:ace_ids).with('read', Portfolio).and_return([portfolio.id])
        end

        it "returns the set limited by the correct portfolio ids" do
          expect(subject.resolve).to eq([portfolio])
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

    context "when the user is only in the user scope" do
      let(:scopes) { %w[user] }

      it "returns the set limited by the portfolio items within the owner group" do
        Insights::API::Common::Request.with_request(default_request) do
          expect(subject.resolve.to_a).to eq([portfolio])
        end
      end


      context "when the owner is not part of any of the portfolio items" do
        let(:modified_user) do
          default_user_hash.tap do |user_hash|
            user_hash["identity"]["user"]["username"] = "test"
          end
        end

        it "returns an empty set" do
          Insights::API::Common::Request.with_request(modified_request(modified_user)) do
            expect(subject.resolve.to_a).to eq([])
          end
        end
      end
    end

    context "when the user is not in any scope somehow" do
      let(:scopes) { %w[test] }

      it "raises an error" do
        expect { subject.resolve }.to raise_error(Catalog::NotAuthorized, "Not Authorized for portfolios")
      end
    end
  end
end
