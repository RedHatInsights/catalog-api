describe RBAC::UnshareResource do
  let(:app_name) { 'catalog' }
  let(:resource) { "portfolios" }
  let(:verbs) { ["read"] }
  let(:resource_id1) { "1" }
  let(:resource_id2) { "2" }
  let(:resource_id3) { "3" }
  let(:group1) { double(:name => 'group1', :uuid => "123") }
  let(:group2) { double(:name => 'group2', :uuid => "12345") }
  let(:group3) { double(:name => 'group3', :uuid => "45665") }
  let(:role1) { double(:name => 'role1-Sharing', :uuid => "67899") }
  let(:role1_detail) { double(:name => 'role1-Sharing', :uuid => "67899", :access => [access1]) }
  let(:role1_detail_updated) { double(:name => 'role1-Sharing', :uuid => "67899", :access => []) }
  let(:role2) { double(:name => 'role2', :uuid => "56779") }
  let(:groups) { [group1, group2, group3] }
  let(:roles) { [role1] }
  let(:policy1) { double(:group => group1, :roles => roles) }
  let(:policies) { [policy1] }
  let(:attr_filter1) { double(:value => resource_id1) }
  let(:attr_filter2) { double(:value => resource_id2) }
  let(:attr_filter3) { double(:value => resource_id3) }
  let(:resource_def1) { double(:attribute_filter => attr_filter1) }
  let(:resource_def2) { double(:attribute_filter => attr_filter2) }
  let(:resource_def3) { double(:attribute_filter => attr_filter3) }
  let(:access1) { double(:permission => "#{app_name}:#{resource}:read", :resource_definitions => [resource_def1]) }
  let(:access2) { double(:permission => "#{app_name}:#{resource}:write", :resource_definitions => [resource_def2]) }
  let(:access3) { double(:permission => "#{app_name}:#{resource}:order", :resource_definitions => []) }
  let(:acls) { [access1, access2, access3] }
  let(:options) do
    { :verbs         => verbs,
      :group_uuids   => group_uuids,
      :app_name      => app_name,
      :resource_ids  => [resource_id1],
      :resource_name => "portfolios" }
  end
  let(:group_uuids) { [group1.uuid, group2.uuid, group3.uuid] }
  let(:subject) { described_class.new(options) }
  let(:api_instance) { double }
  let(:rs_class) { class_double("RBAC::Service").as_stubbed_const(:transfer_nested_constants => true) }

  before do
    allow(rs_class).to receive(:call).with(RBACApiClient::GroupApi).and_yield(api_instance)
    allow(rs_class).to receive(:call).with(RBACApiClient::RoleApi).and_yield(api_instance)
    allow(rs_class).to receive(:call).with(RBACApiClient::PolicyApi).and_yield(api_instance)
  end

  context "invalid group uuid" do
    let(:group_uuids) { %w[1] }
    it "raises exception if group id is invalid" do
      allow(RBAC::Service).to receive(:paginate).with(api_instance, :list_groups, {}).and_return(groups)
      expect { subject.process }.to raise_exception(ActiveRecord::RecordNotFound)
    end
  end

  context "with groups" do
    it "remove resource definitions" do
      allow(RBAC::Service).to receive(:paginate).with(api_instance, :list_groups, {}).and_return(groups)
      allow(RBAC::Service).to receive(:paginate).with(api_instance, :list_roles, {}).and_return([role1, role2])
      allow(RBAC::Service).to receive(:paginate).with(api_instance, :list_policies, {}).and_return(policies)
      allow(api_instance).to receive(:get_role).with(role1.uuid).and_return(role1_detail)
      allow(role1_detail).to receive(:access=)
      allow(api_instance).to receive(:update_role).and_return(role1_detail_updated)
      allow(api_instance).to receive(:delete_role)
      subject.process
    end
  end

  context "with no groups" do
    let(:group_uuids) { [] }
    it "remove resource definitions" do
      allow(RBAC::Service).to receive(:paginate).with(api_instance, :list_groups, {}).and_return(groups)
      allow(RBAC::Service).to receive(:paginate).with(api_instance, :list_roles, {}).and_return([role1, role2])
      allow(api_instance).to receive(:get_role).with(role1.uuid).and_return(role1_detail)
      allow(role1_detail).to receive(:access=)
      allow(api_instance).to receive(:update_role).and_return(role1_detail_updated)
      allow(api_instance).to receive(:delete_role)
      subject.process
    end
  end
end
