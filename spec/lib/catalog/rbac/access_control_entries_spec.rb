describe Catalog::RBAC::AccessControlEntries, :type => [:current_forwardable] do
  around do |example|
    with_modified_env(:RBAC_URL => "http://rbac.example.com") do
      example.call
    end
  end

  describe "#ace_ids" do
    let(:group_pagination) do
      RBACApiClient::GroupPagination.new(
        :meta   => pagination_meta,
        :links  => pagination_links,
        :data   => group_list
      )
    end
    let(:pagination_meta) { RBACApiClient::PaginationMeta.new(:count => 1) }
    let(:pagination_links) { RBACApiClient::PaginationLinks.new }
    let(:group_list) { [RBACApiClient::GroupOut.new(:name => "group", :uuid => "123-456")] }

    before do
      stub_request(:get, "http://rbac.example.com/api/rbac/v1/groups/?limit=10&offset=0&scope=principal").
        to_return(
          :status  => 200,
          :body    => group_pagination.to_json,
          :headers => default_headers
      )
    end

    context "when access control entries exist that match the given parameters" do
      before do
        create(:access_control_entry, :has_read_permission, :aceable_id => "123")
        create(:access_control_entry, :has_read_permission, :aceable_id => "456")
        create(:access_control_entry, :has_read_permission, :aceable_id => "789", :group_uuid => "123-4567")
      end

      it "returns a list of the permitted object ids" do
        expect(subject.ace_ids('read', Portfolio)).to eq(["123", "456"])
      end
    end

    context "when access control entries do not exist that match the given parameters" do
      before do
        create(:access_control_entry, :has_update_permission, :aceable_id => "123")
        create(:access_control_entry, :has_read_permission, :aceable_id => "456", :aceable_type => "PortfolioItem")
        create(:access_control_entry, :has_read_permission, :aceable_id => "789", :group_uuid => "456-123")
      end

      it "returns an empty list" do
        expect(subject.ace_ids('read', Portfolio)).to eq([])
      end
    end
  end
end
