RSpec.shared_context "sharing_objects" do
  let(:app_name) { 'catalog' }
  let!(:shared_portfolio) { create(:portfolio) }
  let(:permissions) { %w[read] }
  let(:http_status) { '204' }
  let(:attributes) { {:group_uuids => group_uuids, :permissions => permissions} }
  let(:ace1) { create(:access_control_entry, :group_uuid => group1.uuid, :permission => permissions[0], :aceable => shared_portfolio) }
  let(:ace2) { create(:access_control_entry, :group_uuid => group2.uuid, :permission => permissions[0], :aceable => shared_portfolio) }
  let(:ace3) { create(:access_control_entry, :group_uuid => group3.uuid, :permission => permissions[0], :aceable => shared_portfolio) }
  let(:rs_class) { class_double("Insights::API::Common::RBAC::Service").as_stubbed_const(:transfer_nested_constants => true) }
  let(:api_instance) { double }
  let(:group_uuids) { [group1.uuid, group2.uuid, group3.uuid] }
  let(:group1) { instance_double(RBACApiClient::GroupOut, :name => 'group1', :uuid => "123") }
  let(:group2) { instance_double(RBACApiClient::GroupOut, :name => 'group2', :uuid => "12345") }
  let(:group3) { instance_double(RBACApiClient::GroupOut, :name => 'group3', :uuid => "45665") }
  let(:groups) { [group1, group2, group3] }
end
