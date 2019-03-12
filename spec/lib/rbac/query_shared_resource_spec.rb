describe RBAC::QuerySharedResource do
  let(:app_name) { 'catalog' }
  let(:resource) { "portfolios" }
  let(:verbs) { ["read"] }
  let(:resource_id1) { "1" }
  let(:role1_uuid) { "1" }
  let(:role2_uuid) { "2" }
  let(:group1) { double(:name => 'group1', :uuid => "123") }
  let(:group2) { double(:name => 'group2', :uuid => "12345") }
  let(:group3) { double(:name => 'group3', :uuid => "45665") }
  let(:role1) { double(:name => 'role1-Sharing', :uuid => role1_uuid) }
  let(:role2) { double(:name => 'role2-Sharing', :uuid => role2_uuid) }
  let(:role1_detail) { double(:name => 'role1-Sharing', :uuid => role1_uuid, :access => [access3]) }
  let(:role2_detail) { double(:name => 'role2-Sharing', :uuid => role2_uuid, :access => [access1, access2]) }
  let(:groups) { [group1, group2, group3] }
  let(:roles) { [role1, role2] }
  let(:policy1) { double(:group => group1, :roles => roles) }
  let(:policies) { [policy1] }
  let(:attr_filter1) { double(:value => resource_id1) }
  let(:resource_def1) { double(:attribute_filter => attr_filter1) }
  let(:access1) { double(:permission => "#{app_name}:#{resource}:read", :resource_definitions => [resource_def1]) }
  let(:access2) { double(:permission => "#{app_name}:#{resource}:write", :resource_definitions => [resource_def1]) }
  let(:access3) { double(:permission => "#{app_name}:#{resource}:order", :resource_definitions => [resource_def1]) }

  let(:options) do
    { :verbs         => verbs,
      :app_name      => app_name,
      :resource_id   => resource_id1,
      :resource_name => resource }
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

  shared_examples_for "#share_info" do
    it "query resource definitions" do
      allow(RBAC::Service).to receive(:paginate).with(api_instance, :list_groups, {}).and_return(groups)
      allow(RBAC::Service).to receive(:paginate).with(api_instance, :list_roles, {}).and_return([role1, role2])
      allow(RBAC::Service).to receive(:paginate).with(api_instance, :list_policies, {}).and_return(policies)

      allow(api_instance).to receive(:get_role).with(role1.uuid).and_return(role1_detail)
      allow(api_instance).to receive(:get_role).with(role2.uuid).and_return(role2_detail)
      obj = subject.process
      expect(obj.share_info.first['verbs']).to match_array(expected_verbs)
    end
  end

  context "with no verbs" do
    let(:verbs) { nil }
    let(:expected_verbs) { %w[read write order] }

    it_behaves_like "#share_info"
  end

  context "with read only verb" do
    let(:verbs) { %w[read] }
    let(:expected_verbs) { verbs }

    it_behaves_like "#share_info"
  end

  context "with read and order verb" do
    let(:verbs) { %w[read order] }
    let(:expected_verbs) { verbs }

    it_behaves_like "#share_info"
  end
end
