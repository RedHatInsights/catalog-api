# load the gem
require 'rbac-api-client'
module RBAC
  class ShareResource
    include Utilities
    def initialize(options)
      @app_name = options[:app_name]
      @resource_name = options[:resource_name]
      @permissions = options[:permissions]
      @resource_ids = options[:resource_ids]
      @group_uuids = SortedSet.new(options[:group_uuids])
      @acls = RBAC::ACLS.new
    end

    def process
      validate_groups
      @roles = RBAC::Roles.new("#{@app_name}-#{@resource_name}-")
      @group_uuids.each { |uuid| manage_roles_for_group(uuid) }
      self
    end

    private

    def manage_roles_for_group(group_uuid)
      @resource_ids.each do |resource_id|
        name = unique_name(resource_id, group_uuid)
        role = @roles.find(name)
        role ? update_existing_role(role, resource_id) : add_new_role(name, group_uuid, resource_id)
      end
    end

    def update_existing_role(role, resource_id)
      role.access = @acls.add(role.access, resource_id, @permissions)
      @roles.update(role) if role.access.present?
    end

    def add_new_role(name, group_uuid, resource_id)
      acls = @acls.create(resource_id, @permissions)
      role = @roles.add(name, acls)
      add_policy(name, group_uuid, role.uuid)
    end

    def add_policy(name, group_uuid, role_uuid)
      RBAC::Service.call(RBACApiClient::PolicyApi) do |api_instance|
        policy_in = RBACApiClient::PolicyIn.new
        policy_in.name = name
        policy_in.description = 'Shared Policy'
        policy_in.group = group_uuid
        policy_in.roles = [role_uuid]
        api_instance.create_policies(policy_in)
      end
    end
  end
end
