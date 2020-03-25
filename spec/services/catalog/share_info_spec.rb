describe Catalog::ShareInfo, :type => :service do
  let(:portfolio) { create(:portfolio) }
  let(:group1) { instance_double(RBACApiClient::GroupOut, :name => 'group1', :uuid => "123") }
  let(:uuids) { [group1.uuid] }
  let(:permissions) { ['read', 'update'] }
  let(:rs_class) { class_double("Insights::API::Common::RBAC::Service").as_stubbed_const(:transfer_nested_constants => true) }
  let(:api_instance) { double }
  let(:principal_options) { {:scope=>"principal"} }
  let(:pagination_options) { {:limit => Catalog::ShareInfo::MAX_GROUPS_LIMIT, :uuid => [group1.uuid]} }

  let(:params) { { :object => portfolio } }

  before do
    allow(rs_class).to receive(:call).with(RBACApiClient::GroupApi).and_yield(api_instance)
    allow(Insights::API::Common::RBAC::Service).to receive(:paginate) do |api_instance, method, options|
      expect(method).to eq(:list_groups)
      expect(options[:limit]).to eq(Catalog::ShareInfo::MAX_GROUPS_LIMIT)
      expect(options[:uuid]).to match_array(uuids) if options.key?(:uuid)
      [group1]
    end
    create(:access_control_entry, :has_read_and_update_permission, :group_uuid => group1.uuid, :aceable => portfolio)
  end

  let(:subject) { described_class.new(params) }

  shared_examples_for "#process" do
    it "#process" do
      info = subject.process.result
      expect(info.count).to eq(1)
      expect(info[0][:group_name]).to eq(group1.name)
      expect(info[0][:group_uuid]).to eq(group1.uuid)
      expect(info[0][:permissions]).to match_array(permissions)
    end
  end

  context "when all group uuids exist" do
    it_behaves_like "#process"
  end

  context "when only some group uuids exist" do
    let(:uuids) { [group1.uuid, 'non-existent'] }
    let(:pagination_options) { {:limit => Catalog::ShareInfo::MAX_GROUPS_LIMIT, :uuid => uuids} }
    before do
      create(:access_control_entry, :has_update_permission, :group_uuid => "non-existent", :aceable => portfolio)
    end

    it_behaves_like "#process"
  end
end
