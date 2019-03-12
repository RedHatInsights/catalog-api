require 'rbac-api-client'
module RBAC
  class UnshareResource
    include Utilities
    def initialize(options)
      @app_name = options[:app_name]
      @resource_ids = options[:resource_ids]
      @resource_name = options[:resource_name]
      @group_uuids = SortedSet.new(options[:group_uuids])
      @regexp = Regexp.new("#{@app_name}:#{@resource_name}:(#{options[:verbs].join('|')})")
    end

    def process
      validate_groups
      @group_uuids.empty? ? all_shared_roles : roles_from_groups
      @deleted_roles = SortedSet.new
      @resource_ids.each do |id|
        update_matching_roles(id)
      end
      self
    end

    private

    def roles_from_groups
      RBAC::Service.call(RBACApiClient::PolicyApi) do |api_instance|
        RBAC::Service.paginate(api_instance, :list_policies, {}).each do |item|
          next unless @group_uuids.include?(item.group.uuid)
          filter_roles(item.roles)
        end
      end
    end

    def all_shared_roles
      RBAC::Service.call(RBACApiClient::RoleApi) do |api_instance|
        RBAC::Service.paginate(api_instance, :list_roles, {}).each do |role|
          filter_roles([role])
        end
      end
    end

    def filter_roles(roles)
      @shared_roles ||= SortedSet.new
      roles.each do |role|
        @shared_roles.add(role.uuid) if role.name.end_with?('-Sharing')
      end
    end

    def update_matching_roles(resource_id)
      RBAC::Service.call(RBACApiClient::RoleApi) do |api_instance|
        @shared_roles.each do |uuid|
          next if @deleted_roles.include?(uuid)
          role = api_instance.get_role(uuid)
          matching_acls = find_matching_acls(role.access, resource_id)
          next if matching_acls.empty?
          update_role(role, resource_id)
          # get the updated role
          role = api_instance.get_role(uuid)
          delete_role(role) if role_access_empty?(role)
        end
      end
    end

    def role_access_empty?(role)
      role.access.count.zero?
    end

    def update_role(role, resource_id)
      role.access = delete_matching_acls(role.access, resource_id)
      RBAC::Service.call(RBACApiClient::RoleApi) do |api_instance|
        api_instance.update_role(role.uuid, role)
      end
    end

    def delete_role(role)
      @deleted_roles.add(role.uuid)
      RBAC::Service.call(RBACApiClient::RoleApi) do |api_instance|
        api_instance.delete_role(role.uuid)
      end
    end
  end
end
