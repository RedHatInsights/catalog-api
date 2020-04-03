describe OrderPolicy::Scope, :type => [:service] do
  let(:user_context) { instance_double(UserContext, :group_uuids => ["123-456"], :access => catalog_access) }
  let(:catalog_access) { instance_double(Insights::API::Common::RBAC::Access, :scopes => scopes) }
  let(:rbac_access) { instance_double(Catalog::RBAC::Access) }
  let(:subject) { described_class.new(user_context, Order) }

  around do |example|
    Insights::API::Common::Request.with_request(default_request) { example.call }
  end

  before do
    allow(Insights::API::Common::RBAC::Access).to receive(:new).and_return(catalog_access)
    allow(catalog_access).to receive(:process).and_return(catalog_access)

    allow(Catalog::RBAC::Access).to receive(:new).with(user_context, order).and_return(rbac_access)
  end

  describe "#resolve" do
    let(:order) { create(:order) }

    context "when the user is in the admin scope" do
      let(:scopes) { %w[admin group user] }

      it "returns all the orders" do
        expect(subject.resolve).to contain_exactly(order)
      end
    end

    context "when the user is in the user scope" do
      let(:scopes) { %w[group user] }

      it "returns the orders by owner" do
        expect(subject.resolve.to_a).to eq([order])
      end

      context "when the owner is not part of any of the orders" do
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
        expect { subject.resolve }.to raise_error(Catalog::NotAuthorized, "Not Authorized for orders")
      end
    end
  end
end
