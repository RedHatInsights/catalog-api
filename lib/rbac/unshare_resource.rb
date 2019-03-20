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
        role = @roles.find(name)
        next unless role
        role.access = @acls.remove(role.access, resource_id, @permissions)
        role.access.present? ? @roles.update(role) : @roles.delete(role)
        @count += 1
      end
    end
  end
end
