# load the gem
require 'rbac-api-client'
require 'securerandom'
module RBAC
  class ShareResource
    include Utilities
    def initialize(options)
      @app_name = options[:app_name]
      @resource_name = options[:resource_name]
      @verbs = options[:verbs]
      @resource_ids = options[:resource_ids]
      @group_uuids  = SortedSet.new(options[:group_uuids])
    end

    def process
      validate_groups
      @group_uuids.each { |uuid| add_policy_for_group(uuid) }
      self
    end

    private

    def add_policy_for_group(group_uuid)
      @resource_ids.each do |resource_id|
        @unique_name = "#{SecureRandom.uuid}-Sharing"
        role = add_role(resource_id)
        add_policy(group_uuid, role.uuid)
      end
    end

    def add_role(resource_id)
      RBAC::Service.call(RBACApiClient::RoleApi) do |api_instance|
        role_in = RBACApiClient::RoleIn.new
        role_in.name = @unique_name
        role_in.access = acl(resource_id)
        api_instance.create_roles(role_in)
      end
    end

    def acl(resource_id)
      resource_def = resource_definition(resource_id)
      @verbs.collect do |verb|
        RBACApiClient::Access.new.tap do |access|
          permission = "#{@app_name}:#{@resource_name}:#{verb}"
          access.permission = permission
          access.resource_definitions = [resource_def]
        end
      end
    end

    def add_policy(group_uuid, role_uuid)
      RBAC::Service.call(RBACApiClient::PolicyApi) do |api_instance|
        policy_in = RBACApiClient::PolicyIn.new
        policy_in.name = @unique_name
        policy_in.description = 'Shared Policy'
        policy_in.group = group_uuid
        policy_in.roles = [role_uuid]
        api_instance.create_policies(policy_in)
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
  end
end
