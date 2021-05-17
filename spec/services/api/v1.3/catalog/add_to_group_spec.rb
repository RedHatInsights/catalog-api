describe Api::V1x3::Catalog::AddToGroup, :type => [:service] do
  include_context "seed_objects"
  around do |example|
    Insights::API::Common::Request.with_request(default_request) { example.call }
  end

  let(:subject) { described_class.new(group_name, group_description, [role_name], user_name) }

  context "group exists" do
    before do
      allow(Insights::API::Common::RBAC::Service).to receive(:call).with(RBACApiClient::GroupApi).and_yield(group_api)
      allow(group_api).to receive(:list_groups).with(group_opts).and_return(group_result)
      allow(group_api).to receive(:list_roles_for_group).with(group_uuid, group_role_opts).and_return(group_role_result)
      allow(group_api).to receive(:add_principal_to_group).with(group_uuid, group_principal_in).and_return(group_with_principal_roles)
    end

    it '#process' do
      expect(subject.process.result).to be_truthy
    end

    it '#process list_groups error' do
      allow(group_api).to receive(:list_groups).with(group_opts).and_raise(rbac_error)
      expect { subject.process }.to raise_exception(RuntimeError, /Error getting group uuid for #{Regexp.quote(group_name)}/)
    end

    it '#process list_roles_for_group error' do
      allow(group_api).to receive(:list_roles_for_group).with(group_uuid, group_role_opts).and_raise(rbac_error)

      expect { subject.process }.to raise_exception(RuntimeError, /Error checking if role #{Regexp.quote(role_name)} exists in group #{Regexp.quote(group_name)}/)
    end

    it '#process add_principal_to_group error' do
      allow(group_api).to receive(:add_principal_to_group).with(group_uuid, group_principal_in).and_raise(rbac_error)

      expect { subject.process }.to raise_exception(RuntimeError, /Error adding user #{Regexp.quote(user_name)} to group #{Regexp.quote(group_name)}/)
    end
  end

  context "group missing" do
    let(:group_pagination_meta) { RBACApiClient::PaginationMeta.new(count: 0) }
    let(:group_result) { RBACApiClient::GroupPagination.new(meta: group_pagination_meta, links: nil, data: []) }
    let(:group) {  RBACApiClient::Group.new(name: group_name, description: group_description) }
    let(:group_out) { RBACApiClient::GroupOut.new(name: group_name, uuid: group_uuid) }
    let(:group_role_pagination_meta) { RBACApiClient::PaginationMeta.new(count: 0) }
    let(:group_role_result) { RBACApiClient::GroupRolesPagination.new(meta: group_role_pagination_meta, links: nil, data: []) }
    let(:zero_role_pagination_meta) { RBACApiClient::PaginationMeta.new(count: 0) }
    let(:empty_role_result) { RBACApiClient::RolePaginationDynamic.new(meta: zero_role_pagination_meta, links: nil, data: []) }
    let(:group_role_in) {  RBACApiClient::GroupRoleIn.new(roles: [role_uuid]) }

    before do
      allow(Insights::API::Common::RBAC::Service).to receive(:call).with(RBACApiClient::GroupApi).and_yield(group_api)
      allow(Insights::API::Common::RBAC::Service).to receive(:call).with(RBACApiClient::RoleApi).and_yield(role_api)
      allow(group_api).to receive(:list_groups).with(group_opts).and_return(group_result)
      allow(group_api).to receive(:create_group).with(group).and_return(group_out)
      allow(group_api).to receive(:list_roles_for_group).with(group_uuid, group_role_opts).and_return(group_role_result)
      allow(role_api).to receive(:list_roles).with(role_opts).and_return(role_result)
      allow(group_api).to receive(:add_role_to_group).with(group_uuid, group_role_in).and_return(RBACApiClient::InlineResponse200.new(data: nil))
      allow(group_api).to receive(:add_principal_to_group).with(group_uuid, group_principal_in).and_return(group_with_principal_roles)
    end

    it '#process' do
      expect(subject.process.result).to be_truthy
    end

    it '#process create_group error' do
      allow(group_api).to receive(:create_group).with(group).and_raise(rbac_error)

      expect { subject.process }.to raise_exception(RuntimeError, /Error adding group #{Regexp.quote(group_name)}/)
    end

    it '#process list_roles error' do
      allow(role_api).to receive(:list_roles).with(role_opts).and_raise(rbac_error)

      expect { subject.process }.to raise_exception(RuntimeError, /Error getting role uuid for #{Regexp.quote(role_name)}/)
    end

    it '#process list_roles missing' do
      allow(role_api).to receive(:list_roles).with(role_opts).and_return(empty_role_result)

      expect { subject.process }.to raise_exception(RuntimeError, /Role #{Regexp.quote(role_name)} does not exist/)
    end

    it '#process add_role_to_group error' do
      allow(group_api).to receive(:add_role_to_group).with(group_uuid, group_role_in).and_raise(rbac_error)

      expect { subject.process }.to raise_exception(RuntimeError, /Error adding role #{Regexp.quote(role_name)} to group #{Regexp.quote(group_name)}/)
    end
  end
end
