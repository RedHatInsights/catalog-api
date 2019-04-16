require 'rbac-api-client'
module RBAC
  class Seed
    def initialize(seed_file, user_file)
      @acl_data = YAML.load_file(seed_file)
      @request = create_request(user_file)
    end

    def process
      ManageIQ::API::Common::Request.with_request(@request) do
        create_groups
        create_roles
        create_policies
      end
    end

    private

    def create_groups
      current = current_groups
      names = current.collect(&:name)
      group = RBACApiClient::Group.new
      begin
        RBAC::Service.call(RBACApiClient::GroupApi) do |api_instance|
          @acl_data['groups'].each do |grp|
            next if names.include?(grp['name'])
            Rails.logger.info("Creating #{grp['name']}")
            group.name = grp['name']
            group.description = grp['description']
            api_instance.create_group(group)
          end
        end
      rescue RBACApiClient::ApiError => e
        Rails.logger.error("Exception when calling GroupApi->create_group: #{e}")
        raise
      end
    end

    def current_groups
      RBAC::Service.call(RBACApiClient::GroupApi) do |api|
        RBAC::Service.paginate(api, :list_groups,  {}).to_a
      end
    end

    def create_roles
      current = current_roles
      names = current.collect(&:name)
      role_in = RBACApiClient::RoleIn.new
      begin
        RBAC::Service.call(RBACApiClient::RoleApi) do |api_instance|
          @acl_data['roles'].each do |role|
            next if names.include?(role['name'])
            role_in.name = role['name']
            role_in.access = []
            role['access'].each do |obj|
              access = RBACApiClient::Access.new
              access.permission = obj['permission']
              access.resource_definition = create_rds(obj)
              role_in.access << access
            end
            api_instance.create_roles(role_in)
          end
        end
      rescue RBACApiClient::ApiError => e
        Rails.logger.error("Exception when calling RoleApi->create_roles: #{e}")
        raise
      end
    end

    def create_rds(obj)
      obj.fetch('resource_definitions', []).collect do |item|
        RBACApiClient::ResourceDefinition.new.tap do |rd|
          rd.attribute_filter = RBACApiClient::ResourceDefinitionFilter.new.tap do |rdf|
            rdf.key = item['attribute_filter']['key']
            rdf.value = item['attribute_filter']['value']
            rdf.operation = item['attribute_filter']['operation']
          end
        end
      end
    end

    def current_roles
      RBAC::Service.call(RBACApiClient::RoleApi) do |api|
        RBAC::Service.paginate(api, :list_roles, {}).to_a
      end
    end

    def create_policies
      names = current_policies.collect(&:name)
      groups = current_groups
      roles = current_roles
      policy_in = RBACApiClient::PolicyIn.new
      begin
        RBAC::Service.call(RBACApiClient::PolicyApi) do |api_instance|
          @acl_data['policies'].each do |policy|
            next if names.include?(policy['name'])
            policy_in.name = policy['name']
            policy_in.description = policy['description']
            policy_in.group = find_uuid('Group', groups, policy['group']['name'])
            policy_in.roles = [find_uuid('Role', roles, policy['role']['name'])]
            api_instance.create_policies(policy_in)
          end
        end
      rescue RBACApiClient::ApiError => e
        Rails.logger.error("Exception when calling PolicyApi->create_policies: #{e}")
        raise
      end
    end

    def current_policies
      RBAC::Service.call(RBACApiClient::PolicyApi) do |api|
        RBAC::Service.paginate(api, :list_policies, {}).to_a
      end
    end

    def find_uuid(type, data, name)
      result = data.detect { |item| item.name == name }
      raise "#{type} #{name} not found in RBAC service" unless result
      result.uuid
    end

    def create_request(user_file)
      raise "File #{user_file} not found" unless File.exist?(user_file)
      user = YAML.load_file(user_file)
      {:headers => {'x-rh-identity' => Base64.strict_encode64(user.to_json)}, :original_url => '/'}
    end
  end
end
