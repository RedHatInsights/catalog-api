module RBAC
  module Utilities
    def validate_groups
      RBAC::Service.call(RBACApiClient::GroupApi) do |api|
        uuids = SortedSet.new
        RBAC::Service.paginate(api, :list_groups, {}).each { |group| uuids << group.uuid }
        missing = @group_uuids - uuids
        raise ActiveRecord::RecordNotFound, "The following group uuids are missing #{missing.to_a.join(",")}" unless missing.empty?
      end
    end

    def find_matching_acls(acls, resource_id)
      acls.select { |access| matches?(access, resource_id) }
    end

    def delete_matching_acls(acls, resource_id)
      acls.delete_if { |access| matches?(access, resource_id) }
    end

    def matches?(access, resource_id)
      @regexp.match(access.permission) &&
        access.resource_definitions.any? { |rdf| rdf.attribute_filter.value == resource_id }
    end
  end
end
