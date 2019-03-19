require 'rbac-api-client'
module RBAC
  class UnshareResource < ShareResource
    attr_accessor :count
    def initialize(options)
      @count = 0
      super
    end

    private

    def manage_roles_for_group(group_uuid)
      @resource_ids.each do |resource_id|
        name = unique_name(resource_id, group_uuid)
        role = @roles.find_role_by_name(name)
        next unless role
        role.access = remove_acls(role.access, resource_id, @permissions)
        role.access.present? ? @roles.update_role(role) : @roles.delete_role(role)
        @count += 1
      end
    end
  end
end
