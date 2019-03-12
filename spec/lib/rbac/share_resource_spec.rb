describe RBAC::ShareResource do
  let(:app_name) { 'catalog' }
  let(:resource) { "portfolio" }
  let(:verbs) { ["read"] }
  let(:group1) { double(:name => 'group1', :uuid => "123") }
  let(:group2) { double(:name => 'group2', :uuid => "12345") }
  let(:group3) { double(:name => 'group3', :uuid => "45665") }
  let(:role) { double(:name => 'role1', :uuid => "67899") }

  let(:groups) { [group1, group2, group3] }
  let(:options) do
    { :verbs         => verbs,
      :group_uuids   => group_uuids,
      :app_name      => app_name,
      :resource_ids  => %w[4 5],
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
    let(:group_uuids) { ["1"] }
    it "raises exception if group id is invalid" do
      allow(RBAC::Service).to receive(:paginate).with(api_instance, :list_groups, {}).and_return(groups)
      expect { subject.process }.to raise_exception(ActiveRecord::RecordNotFound)
    end
  end

  context "valid groups" do
    it "add resource definitions" do
      allow(RBAC::Service).to receive(:paginate).with(api_instance, :list_groups, {}).and_return(groups)
      allow(api_instance).to receive(:create_roles).and_return(role)
      expect(api_instance).to receive(:create_policies).exactly(6).times

      subject.process
    end
  end
end
