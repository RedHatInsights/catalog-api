describe Catalog::UnshareResource, :type => :service do
  let(:portfolio) { create(:portfolio) }
  let(:group1) { instance_double(RBACApiClient::GroupOut, :name => 'group1', :uuid => "123") }
  let(:permissions) { ['read', 'update'] }
  let(:rs_class) { class_double("Insights::API::Common::RBAC::Service").as_stubbed_const(:transfer_nested_constants => true) }
  let(:api_instance) { double }
  let(:principal_options) { {:scope=>"principal"} }

  let(:params) do
    { :group_uuids => [group1.uuid],
      :permissions => permissions,
      :object      => portfolio }
  end

  before do
    allow(rs_class).to receive(:call).with(RBACApiClient::GroupApi).and_yield(api_instance)
    allow(Insights::API::Common::RBAC::Service).to receive(:paginate).with(api_instance, :list_groups, principal_options).and_return([group1])
    allow(Insights::API::Common::RBAC::Service).to receive(:paginate).with(api_instance, :list_groups, {}).and_return([group1])
    create(:access_control_entry, :group_uuid => group1.uuid, :permission => permissions[0], :aceable => portfolio)
    create(:access_control_entry, :group_uuid => group1.uuid, :permission => permissions[1], :aceable => portfolio)
  end

  let(:subject) { described_class.new(params) }

  it "#process" do
    expect(portfolio.access_control_entries.count).to eq(2)
    subject.process
    portfolio.reload
    expect(portfolio.access_control_entries.count).to eq(0)
  end
end
