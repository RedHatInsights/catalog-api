describe Catalog::RBAC::Role, :type => [:current_forwardable] do
  let(:subject) { described_class }

  around do |example|
    with_modified_env(:RBAC_URL => "http://rbac.example.com") do
      example.call
    end
  end

  let(:role_pagination) do
    RBACApiClient::RolePagination.new(
      :meta   => pagination_meta,
      :links  => pagination_links,
      :data   => role_list
    )
  end
  let(:pagination_meta) { RBACApiClient::PaginationMeta.new(:count => 1) }
  let(:pagination_links) { RBACApiClient::PaginationLinks.new }
  let(:role_list) { [RBACApiClient::RoleOut.new(:name => role_name, :uuid => "123-456")] }

  describe ".catalog_administrator?" do
    before do
      stub_request(:get, "http://rbac.example.com/api/rbac/v1/roles/?limit=10&name=Catalog%20Administrator&offset=0&scope=principal").
        to_return(
          :status  => 200,
          :body    => role_pagination.to_json,
          :headers => default_headers
      )
    end

    context "when an assigned role exists" do
      let(:role_list) { [RBACApiClient::RoleOut.new(:name => "role", :uuid => "123-456")] }

      it "returns true" do
        expect(subject.catalog_administrator?).to eq(true)
      end
    end

    context "when an assigned role does not exist" do
      let(:role_list) { [] }

      it "returns false" do
        expect(subject.catalog_administrator?).to eq(false)
      end
    end
  end

  describe ".role_check" do
    before do
      allow(Insights::API::Common::RBAC::Access).to receive(:enabled?).and_return(enabled?)
    end

    context "when RBAC access is enabled" do
      let(:enabled?) { true }

      before do
        stub_request(:get, "http://rbac.example.com/api/rbac/v1/roles/?limit=10&name=test&offset=0&scope=principal").
          to_return(
            :status  => 200,
            :body    => role_pagination.to_json,
            :headers => default_headers
        )

      end

      context "when an assigned role exists" do
        let(:role_list) { [RBACApiClient::RoleOut.new(:name => "role", :uuid => "123-456")] }

        it "returns nil" do
          expect(subject.role_check("test")).to eq(nil)
        end
      end

      context "when an assigned role doesn't exist" do
        let(:role_list) { [] }

        it "raises an error" do
          expect { subject.role_check("test") }.to raise_error(Catalog::NotAuthorized)
        end
      end
    end

    context "when RBAC access is not enabled" do
      let(:enabled?) { false }

      it "returns nil" do
        expect(subject.role_check("test")).to eq(nil)
      end
    end
  end
end
