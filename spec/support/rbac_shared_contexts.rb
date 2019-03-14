RSpec.shared_context "rbac_objects" do
  let(:app_name) { 'catalog' }
  let(:resource) { "portfolios" }
  let(:verbs) { ["read"] }
  let(:resource_id1) { "1" }
  let(:resource_id2) { "2" }
  let(:resource_id3) { "3" }
  let(:group1) { double(:name => 'group1', :uuid => "123") }
  let(:group2) { double(:name => 'group2', :uuid => "12345") }
  let(:group3) { double(:name => 'group3', :uuid => "45665") }
  let(:role1) { double(:name => 'role1-Sharing', :uuid => "67899") }
  let(:role2) { double(:name => 'role2', :uuid => "56779") }
  let(:role1_detail) { double(:name => role1.name, :uuid => role1.uuid, :access => [access1]) }
  let(:role2_detail) { double(:name => role2.name, :uuid => role2.uuid, :access => []) }
  let(:role1_detail_updated) { double(:name => role1.name, :uuid => role1.uuid, :access => []) }
  let(:groups) { [group1, group2, group3] }
  let(:roles) { [role1] }
  let(:policy1) { double(:group => group1, :roles => roles) }
  let(:policies) { [policy1] }
  let(:attr_filter1) { double(:value => resource_id1) }
  let(:attr_filter2) { double(:value => resource_id2) }
  let(:attr_filter3) { double(:value => resource_id3) }
  let(:resource_def1) { double(:attribute_filter => attr_filter1) }
  let(:resource_def2) { double(:attribute_filter => attr_filter2) }
  let(:resource_def3) { double(:attribute_filter => attr_filter3) }
  let(:access1) { double(:permission => "#{app_name}:#{resource}:read", :resource_definitions => [resource_def1]) }
  let(:access2) { double(:permission => "#{app_name}:#{resource}:write", :resource_definitions => [resource_def2]) }
  let(:access3) { double(:permission => "#{app_name}:#{resource}:order", :resource_definitions => []) }
  let(:acls) { [access1, access2, access3] }
  let(:group_uuids) { [group1.uuid, group2.uuid, group3.uuid] }
  let(:api_instance) { double }
  let(:rs_class) { class_double("RBAC::Service").as_stubbed_const(:transfer_nested_constants => true) }
  let(:shared_role1) { double(:name => 'role1-Sharing', :uuid => "56779") }
  let(:shared_role2) { double(:name => 'role2-Sharing', :uuid => "56770") }
  let(:shared_role1_detail) { double(:name => shared_role1.name, :uuid => shared_role1.uuid, :access => [resource1_access1]) }
  let(:shared_role2_detail) { double(:name => shared_role2.name, :uuid => shared_role2.uuid, :access => [resource1_access2, resource1_access3]) }
  let(:resource1_access1) { double(:permission => "#{app_name}:#{resource}:read", :resource_definitions => [resource_def1]) }
  let(:resource1_access2) { double(:permission => "#{app_name}:#{resource}:write", :resource_definitions => [resource_def1]) }
  let(:resource1_access3) { double(:permission => "#{app_name}:#{resource}:order", :resource_definitions => [resource_def1]) }
  let(:subject) { described_class.new(options) }
end
