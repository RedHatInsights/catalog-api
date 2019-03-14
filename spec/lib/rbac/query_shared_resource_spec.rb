describe RBAC::QuerySharedResource do
  include_context "rbac_objects"

  let(:options) do
    { :verbs         => verbs,
      :app_name      => app_name,
      :resource_id   => resource_id1,
      :resource_name => resource }
  end
  let(:roles) { [shared_role1, shared_role2] }

  before do
    allow(rs_class).to receive(:call).with(RBACApiClient::GroupApi).and_yield(api_instance)
    allow(rs_class).to receive(:call).with(RBACApiClient::RoleApi).and_yield(api_instance)
    allow(rs_class).to receive(:call).with(RBACApiClient::PolicyApi).and_yield(api_instance)
  end

  shared_examples_for "#share_info" do
    it "query resource definitions" do
      allow(RBAC::Service).to receive(:paginate).with(api_instance, :list_groups, {}).and_return(groups)
      allow(RBAC::Service).to receive(:paginate).with(api_instance, :list_policies, {}).and_return(policies)
      allow(api_instance).to receive(:get_role).with(shared_role1.uuid).and_return(shared_role1_detail)
      allow(api_instance).to receive(:get_role).with(shared_role2.uuid).and_return(shared_role2_detail)

      obj = subject.process
      expect(obj.share_info.first['permissions']).to match_array(expected_permissions)
    end
  end

  context "with no verbs" do
    let(:verbs) { nil }
    let(:expected_permissions) { %w[read write order] }

    it_behaves_like "#share_info"
  end

  context "with read only verb" do
    let(:verbs) { %w[read] }
    let(:expected_permissions) { verbs }

    it_behaves_like "#share_info"
  end

  context "with read and order verb" do
    let(:verbs) { %w[read order] }
    let(:expected_permissions) { verbs }

    it_behaves_like "#share_info"
  end
end
