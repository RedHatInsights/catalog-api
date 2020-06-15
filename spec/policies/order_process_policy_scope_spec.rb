describe OrderProcessPolicy::Scope, :type => [:service] do
  let(:rbac_access) { instance_double(Catalog::RBAC::Access) }
  let(:catalog_access) { instance_double(Insights::API::Common::RBAC::Access, :scopes => scopes) }
  let(:user_context) { instance_double(UserContext, :access => catalog_access) }
  let(:subject) { described_class.new(user_context, OrderProcess) }

  before do
    allow(Insights::API::Common::RBAC::Access).to receive(:new).and_return(catalog_access)
    allow(catalog_access).to receive(:process).and_return(catalog_access)

    allow(Catalog::RBAC::Access).to receive(:new).with(user_context, order_process).and_return(rbac_access)
  end

  describe "#resolve" do
    let(:order_process) { create(:order_process) }

    context "when in admin scope" do
      let(:scopes) { ["admin"] }

      it "returns all the order processes" do
        expect(subject.resolve).to contain_exactly(order_process)
      end
    end

    context "when not in admin scope" do
      let(:scopes) { %w[group user] }

      it "raises an error" do
        expect { subject.resolve }.to raise_error(Catalog::NotAuthorized, "Not Authorized for order_processes")
      end
    end
  end
end
