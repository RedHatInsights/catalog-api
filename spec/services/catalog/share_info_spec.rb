describe Catalog::ShareInfo, :type => :service do
  let(:portfolio) { create(:portfolio) }
  let(:group1) { instance_double(RBACApiClient::GroupOut, :name => 'group1', :uuid => "123") }
  let(:permissions) { ['read', 'update'] }
  let(:rs_class) { class_double("Insights::API::Common::RBAC::Service").as_stubbed_const(:transfer_nested_constants => true) }
  let(:api_instance) { double }
  let(:principal_options) { {:scope=>"principal"} }

  let(:params) { { :object => portfolio } }

  before do
    allow(rs_class).to receive(:call).with(RBACApiClient::GroupApi).and_yield(api_instance)
    allow(Insights::API::Common::RBAC::Service).to receive(:paginate).with(api_instance, :list_groups, principal_options).and_return([group1])
    allow(Insights::API::Common::RBAC::Service).to receive(:paginate).with(api_instance, :list_groups, {}).and_return([group1])
    create(:access_control_entry, :group_uuid => group1.uuid, :permission => permissions[0], :aceable => portfolio)
    create(:access_control_entry, :group_uuid => group1.uuid, :permission => permissions[1], :aceable => portfolio)
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
    before do
      create(:access_control_entry, :group_uuid => "non-existent", :permission => permissions[1], :aceable => portfolio)
    end

    it_behaves_like "#process"
  end
end
