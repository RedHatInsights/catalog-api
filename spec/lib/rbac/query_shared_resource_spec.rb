describe RBAC::QuerySharedResource do
  include_context "rbac_objects"

  let(:options) do
    { :permissions   => permissions,
      :app_name      => app_name,
      :resource_id   => resource_id1,
      :resource_name => resource }
  end
  let(:pagination_options) { { :limit => 100, :name => "catalog-portfolios-#{resource_id1}" } }

  let(:access1) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:#{resource}:read", :resource_definitions => [resource_def1]) }
  let(:access2) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:#{resource}:write", :resource_definitions => [resource_def1]) }
  let(:access3) { instance_double(RBACApiClient::Access, :permission => "#{app_name}:#{resource}:order", :resource_definitions => [resource_def1]) }
  let(:role1_detail) { instance_double(RBACApiClient::RoleWithAccess, :name => role1.name, :uuid => role1.uuid, :access => [access1, access2, access3]) }
  let(:roles) { [role1, role2] }
  let(:subject) { described_class.new(options) }

  before do
    allow(rs_class).to receive(:call).with(RBACApiClient::GroupApi).and_yield(api_instance)
    allow(rs_class).to receive(:call).with(RBACApiClient::RoleApi).and_yield(api_instance)
    allow(rs_class).to receive(:call).with(RBACApiClient::PolicyApi).and_yield(api_instance)
  end

  shared_examples_for "#share_info" do
    it "query resource definitions" do
      allow(RBAC::Service).to receive(:paginate).with(api_instance, :list_groups, {}).and_return(groups)
      allow(RBAC::Service).to receive(:paginate).with(api_instance, :list_policies, {}).and_return(policies)
      allow(RBAC::Service).to receive(:paginate).with(api_instance, :list_roles, pagination_options).and_return([role1, role2])
      allow(api_instance).to receive(:get_group).with(group1.uuid).and_return(group1)
      allow(api_instance).to receive(:get_role).with(role1.uuid).and_return(role1_detail)
      allow(api_instance).to receive(:get_role).with(role2.uuid).and_return(role2_detail)

      obj = subject.process
      expect(obj.share_info.first['permissions']).to match_array(expected_permissions)
    end
  end

  context "all permissions" do
    let(:expected_permissions) { %w[catalog:portfolios:read catalog:portfolios:write catalog:portfolios:order] }

    it_behaves_like "#share_info"
  end
end
