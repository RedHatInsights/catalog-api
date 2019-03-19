describe RBAC::ShareResource do
  include_context "rbac_objects"

  let(:options) do
    { :permissions   => permissions,
      :group_uuids   => group_uuids,
      :app_name      => app_name,
      :resource_ids  => resource_ids,
      :resource_name => resource }
  end
  let(:subject) { described_class.new(options) }
  let(:pagination_options) { { :limit => 100, :name => "catalog-portfolios-" } }

  before do
    allow(rs_class).to receive(:call).with(RBACApiClient::GroupApi).and_yield(api_instance)
    allow(rs_class).to receive(:call).with(RBACApiClient::RoleApi).and_yield(api_instance)
    allow(rs_class).to receive(:call).with(RBACApiClient::PolicyApi).and_yield(api_instance)
  end

  context "invalid group uuid" do
    let(:group_uuids) { ["1"] }
    let(:resource_ids) { ["1"] }
    it "raises exception if group id is invalid" do
      allow(RBAC::Service).to receive(:paginate).with(api_instance, :list_groups, {}).and_return(groups)
      allow(RBAC::Service).to receive(:paginate).with(api_instance, :list_roles, pagination_options).and_return(roles)
      expect { subject.process }.to raise_exception(ActiveRecord::RecordNotFound)
    end
  end

  context "valid groups" do
    let(:resource_ids) { %w[4 5] }
    it "new roles" do
      allow(RBAC::Service).to receive(:paginate).with(api_instance, :list_groups, {}).and_return(groups)
      allow(RBAC::Service).to receive(:paginate).with(api_instance, :list_roles, pagination_options).and_return(roles)
      allow(api_instance).to receive(:create_roles).and_return(role1)

      expect(api_instance).to receive(:create_policies).exactly(6).times

      subject.process
    end
  end

  context "valid groups" do
    let(:resource_ids) { [resource_id1, "2"] }
    let(:permissions) { ["#{app_name}:#{resource}:order", "#{app_name}:#{resource}:read"] }
    it "update roles" do
      allow(RBAC::Service).to receive(:paginate).with(api_instance, :list_groups, {}).and_return(groups)
      allow(RBAC::Service).to receive(:paginate).with(api_instance, :list_roles, pagination_options).and_return(roles)
      allow(api_instance).to receive(:create_roles).and_return(role2)
      allow(api_instance).to receive(:get_role).with(role1.uuid).and_return(role1_detail)
      expect(role1_detail).to receive(:access=).exactly(1).times
      allow(api_instance).to receive(:update_role).exactly(1).times
      expect(api_instance).to receive(:create_policies).exactly(5).times
      subject.process
    end
  end
end
