describe Catalog::RBAC::Group, :type => [:current_forwardable] do
  let(:meta) { RBACApiClient::PaginationMeta.new(:count => 1) }
  let(:groups) { RBACApiClient::GroupPagination.new(:meta => meta, :links => nil, :data => [group_out]) }
  let(:group_out) { RBACApiClient::GroupOut.new(:name => "group1", :uuid => "123") }
  let(:group_uuids) { SortedSet.new(["123"]) }

  subject { described_class.new(group_uuids) }

  before do
    stub_request(:get, "http://rbac/api/rbac/v1/groups/?limit=10&offset=0")
      .to_return(
        :status  => 200,
        :body    => groups.to_json,
        :headers => default_headers
      )

    allow(Insights::API::Common::RBAC::Access).to receive(:enabled?).and_return(rbac_enabled?)
  end

  around do |example|
    with_modified_env(:RBAC_URL => "http://rbac") do
      example.call
    end
  end

  describe "#check" do
    context "when rbac is enabled" do
      let(:rbac_enabled?) { true }

      context "when there are group uuids missing" do
        let(:group_uuids) { SortedSet.new(["123", "456"]) }

        it "throws an error" do
          expect { subject.check }.to raise_error(
            Insights::API::Common::InvalidParameter,
            /group uuids are missing 456/
          )
        end
      end

      context "when there are not group uuids missing" do
        it "validates the groups without an error" do
          subject.check
          expect(a_request(:get, "http://rbac/api/rbac/v1/groups/?limit=10&offset=0")).to have_been_made
        end

        it "returns nil" do
          expect(subject.check).to eq(nil)
        end
      end
    end

    context "when rbac is not enabled" do
      let(:rbac_enabled?) { false }

      it "does not validate the groups" do
        subject.check
        expect(a_request(:get, "http://rbac/api/rbac/v1/groups/?limit=10&offset=0")).not_to have_been_made
      end

      it "returns true" do
        expect(subject.check).to eq(nil)
      end
    end
  end
end
