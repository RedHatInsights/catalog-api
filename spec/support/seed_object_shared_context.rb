RSpec.shared_context "seed_objects" do
  let(:group_name) { "Crane Operators" }
  let(:group_description) { "Brontosaurus Experts" }
  let(:role_name) { "Geological Engineer" }
  let(:user_name) { "Fred Flintstone" }
  let(:group_uuid) { "123456-889" }
  let(:role_uuid) { "5678-900" }
  let(:number_of_groups) { 1 }
  let(:number_of_group_roles) { 1 }
  let(:number_of_roles) { 1 }
  let(:group_api) { instance_double(RBACApiClient::GroupApi) }
  let(:role_api) { instance_double(RBACApiClient::RoleApi) }
  let(:group_list) { [RBACApiClient::GroupOut.new(:name => group_name, :uuid => group_uuid)] }
  let(:role_list) { [RBACApiClient::RoleOut.new(:name => role_name, :uuid => role_uuid)] }
  let(:group_opts) { { name: group_name } }
  let(:group_role_opts) { { role_name: role_name } }
  let(:role_opts) { { name: role_name } }
  let(:principal) { RBACApiClient::PrincipalIn.new(username: user_name) }
  let(:group_principal_in) { RBACApiClient::GroupPrincipalIn.new(principals: [principal]) }
  let(:group_with_principal_roles) {  RBACApiClient::GroupWithPrincipalsAndRoles.new() }
  let(:group_pagination_meta) { RBACApiClient::PaginationMeta.new(count: number_of_groups) }
  let(:group_role_pagination_meta) { RBACApiClient::PaginationMeta.new(count: number_of_group_roles) }
  let(:role_pagination_meta) { RBACApiClient::PaginationMeta.new(count: number_of_roles) }
  let(:group_result) { RBACApiClient::GroupPagination.new(meta: group_pagination_meta, links: nil, data: group_list) }
  let(:group_role_result) { RBACApiClient::GroupRolesPagination.new(meta: group_role_pagination_meta, links: nil, data: role_list) }
  let(:role_result) { RBACApiClient::RolePaginationDynamic.new(meta: role_pagination_meta, links: nil, data: role_list) }
  let(:rbac_error) { RBACApiClient::ApiError.new(:message => 'Kaboom') }
end
