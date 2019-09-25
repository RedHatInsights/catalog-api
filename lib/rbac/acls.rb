module RBAC
  class ACLS
    def create(resource_id, permissions)
      permissions.collect do |permission|
        create_acl(permission, resource_id)
      end
    end

    def remove(acls, resource_id, permissions)
      permissions.each_with_object(acls) do |permission, as|
        delete_matching(as, resource_id, permission)
      end
    end

    def add(acls, resource_id, permissions)
      new_acls = permissions.each_with_object([]) do |permission, as|
        next if find_matching(acls, resource_id, permission)

        as << create_acl(permission, resource_id)
      end
      new_acls.empty? ? acls : new_acls + acls
    end

    def resource_defintions_empty?(acls, permission)
      acls.each do |acl|
        if acl.permission == permission
          return acl.resource_definitions.empty?
        end
      end
      true
    end

    private

    def create_acl(permission, resource_id = nil)
      resource_def = resource_definition(resource_id) if resource_id
      RBACApiClient::Access.new.tap do |access|
        access.permission = permission
        access.resource_definitions = resource_def ? [resource_def] : []
      end
    end

    def resource_definition(resource_id)
      rdf = RBACApiClient::ResourceDefinitionFilter.new.tap do |obj|
        obj.key       = 'id'
        obj.operation = 'equal'
        obj.value     = resource_id.to_s
      end

      RBACApiClient::ResourceDefinition.new.tap do |rd|
        rd.attribute_filter = rdf
      end
    end

    def matches?(access, resource_id, permission)
      access.permission == permission &&
        access.resource_definitions.any? { |rdf| rdf.attribute_filter.key == 'id' && rdf.attribute_filter.operation == 'equal' && rdf.attribute_filter.value == resource_id.to_s }
    end

    def find_matching(acls, resource_id, permission)
      acls.detect { |access| matches?(access, resource_id, permission) }
    end

    def delete_matching(acls, resource_id, permission)
      acls.delete_if { |access| matches?(access, resource_id, permission) }
    end
  end
end
