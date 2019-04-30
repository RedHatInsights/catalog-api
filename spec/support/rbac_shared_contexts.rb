RSpec.shared_context "rbac_objects" do
  let(:app_name) { 'catalog' }
  let(:resource) { "portfolios" }
  let(:permissions) { ["#{app_name}:#{resource}:read"] }
  let(:resource_id1) { "1" }
  let(:resource_id2) { "2" }
  let(:resource_id3) { "3" }
  let(:group1) { double(:name => 'group1', :uuid => "123") }
  let(:group2) { double(:name => 'group2', :uuid => "12345") }
  let(:group3) { double(:name => 'group3', :uuid => "45665") }
  let(:role1) { double(:name => "#{app_name}-#{resource}-#{resource_id1}-group-#{group1.uuid}", :uuid => "67899") }
  let(:role2) { double(:name => "#{app_name}-#{resource}-#{resource_id2}-group-#{group1.uuid}", :uuid => "55555") }
  let(:role1_detail) { double(:name => role1.name, :uuid => role1.uuid, :access => [access1]) }
  let(:role2_detail) { double(:name => role2.name, :uuid => role2.uuid, :access => []) }
  let(:role1_detail_updated) { double(:name => role1.name, :uuid => role1.uuid, :access => []) }
  let(:groups) { [group1, group2, group3] }
  let(:roles) { [role1] }
  let(:policies) { [double(:group => group1, :roles => roles)] }
  let(:resource_def1) { double(:attribute_filter => double(:key => 'id', :operation => 'equal', :value => resource_id1)) }
  let(:resource_def2) { double(:attribute_filter => double(:key => 'id', :operation => 'equal', :value => resource_id2)) }
  let(:resource_def3) { double(:attribute_filter => double(:key => 'id', :operation => 'equal', :value => resource_id3)) }
  let(:access1) { double(:permission => "#{app_name}:#{resource}:read", :resource_definitions => [resource_def1]) }
  let(:access2) { double(:permission => "#{app_name}:#{resource}:write", :resource_definitions => [resource_def2]) }
  let(:access3) { double(:permission => "#{app_name}:#{resource}:order", :resource_definitions => []) }
  let(:group_uuids) { [group1.uuid, group2.uuid, group3.uuid] }
  let(:api_instance) { double }
  let(:rs_class) { class_double("RBAC::Service").as_stubbed_const(:transfer_nested_constants => true) }
  let(:current_user) { '{{username}}' }
  let(:id_value) { '*' }
  let(:owner_resource_def) { double(:attribute_filter => double(:key => 'owner', :operation => 'equal', :value => current_user)) }
  let(:id_resource_def) { double(:attribute_filter => double(:key => 'id', :operation => 'equal', :value => id_value)) }
  let(:owner_resource) { 'orders' }
  let(:owner_permission) { "#{app_name}:#{owner_resource}:read" }
  let(:owner_access) { double(:permission => owner_permission, :resource_definitions => [owner_resource_def]) }
  let(:all_access) { double(:permission => owner_permission, :resource_definitions => [id_resource_def]) }
end
