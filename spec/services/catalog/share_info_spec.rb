describe Catalog::ShareInfo, :type => :service do
  let(:portfolio) { create(:portfolio) }
  let(:group1) { instance_double(RBACApiClient::GroupOut, :name => 'group1', :uuid => "123") }
  let(:group2) { instance_double(RBACApiClient::GroupOut, :name => 'group2', :uuid => "321") }
  let(:uuids) { [group1.uuid] }
  let(:permissions) { ['read', 'update'] }
  let(:rs_class) { class_double("Insights::API::Common::RBAC::Service").as_stubbed_const(:transfer_nested_constants => true) }
  let(:api_instance) { double }
  let(:principal_options) { {:scope=>"principal"} }
  let(:pagination_options) { {:limit => Catalog::ShareInfo::MAX_GROUPS_LIMIT, :uuid => [group1.uuid]} }
  let(:group_list) { [group1] }

  let(:params) { { :object => portfolio } }

  before do
    allow(rs_class).to receive(:call).with(RBACApiClient::GroupApi).and_yield(api_instance)
    allow(Insights::API::Common::RBAC::Service).to receive(:paginate) do |api_instance, method, options|
      expect(method).to eq(:list_groups)
      expect(options[:limit]).to eq(Catalog::ShareInfo::MAX_GROUPS_LIMIT)
      expect(options[:uuid]).to match_array(uuids) if options.key?(:uuid)
      group_list
    end
  end

  let(:subject) { described_class.new(params) }

  shared_examples_for "#process" do
    it "gets the correct group name, group uuid, and permissions" do
      info = subject.process.result
      expect(info.count).to eq(1)
      expect(info[0][:group_name]).to eq(group1.name)
      expect(info[0][:group_uuid]).to eq(group1.uuid)
      expect(info[0][:permissions]).to match_array(permissions)
    end
  end

  describe "#process" do
    context "when all group uuids exist" do
      before do
        create(:access_control_entry, :has_read_and_update_permission, :group_uuid => group1.uuid, :aceable => portfolio)
      end

      it_behaves_like "#process"
    end

    context "when only some group uuids exist" do
      let(:uuids) { [group1.uuid, 'non-existent'] }
      let(:pagination_options) { {:limit => Catalog::ShareInfo::MAX_GROUPS_LIMIT, :uuid => uuids} }
      before do
        create(:access_control_entry, :has_read_and_update_permission, :group_uuid => group1.uuid, :aceable => portfolio)
        create(:access_control_entry, :has_update_permission, :group_uuid => "non-existent", :aceable => portfolio)
      end

      it_behaves_like "#process"
    end

    context "when there are no permissions for the access control entry" do
      before do
        create(:access_control_entry, :group_uuid => group1.uuid, :aceable => portfolio)
      end

      it "returns an empty array" do
        expect(subject.process.result.count).to eq(0)
      end
    end

    context "when there are no permissions for one access control entry but permissions for another" do
      let(:uuids) { [group1.uuid, group2.uuid] }
      let(:pagination_options) { {:limit => Catalog::ShareInfo::MAX_GROUPS_LIMIT, :uuid => uuids} }
      let(:group_list) { [group1, group2] }

      before do
        create(:access_control_entry, :group_uuid => group1.uuid, :aceable => portfolio)
        create(:access_control_entry, :has_update_permission, :group_uuid => group2.uuid, :aceable => portfolio)
      end

      it "returns the permissions for the group with permissions" do
        share_info = subject.process.result
        expect(share_info.count).to eq(1)
        expect(share_info[0][:group_name]).to eq(group2.name)
        expect(share_info[0][:group_uuid]).to eq(group2.uuid)
        expect(share_info[0][:permissions]).to match_array(["update"])
      end
    end
  end
end
