describe RBAC::ShareResource do
  include_context "rbac_objects"

  let(:options) do
    { :verbs         => verbs,
      :group_uuids   => group_uuids,
      :app_name      => app_name,
      :resource_ids  => %w[4 5],
      :resource_name => "portfolios" }
  end

  before do
    allow(rs_class).to receive(:call).with(RBACApiClient::GroupApi).and_yield(api_instance)
    allow(rs_class).to receive(:call).with(RBACApiClient::RoleApi).and_yield(api_instance)
    allow(rs_class).to receive(:call).with(RBACApiClient::PolicyApi).and_yield(api_instance)
  end

  context "invalid group uuid" do
    let(:group_uuids) { ["1"] }
    it "raises exception if group id is invalid" do
      allow(RBAC::Service).to receive(:paginate).with(api_instance, :list_groups, {}).and_return(groups)
      expect { subject.process }.to raise_exception(ActiveRecord::RecordNotFound)
    end
  end

  context "valid groups" do
    it "add resource definitions" do
      allow(RBAC::Service).to receive(:paginate).with(api_instance, :list_groups, {}).and_return(groups)
      allow(api_instance).to receive(:create_roles).and_return(role1)
      expect(api_instance).to receive(:create_policies).exactly(6).times

      subject.process
    end
  end
end
