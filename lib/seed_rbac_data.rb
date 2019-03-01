class SeedRBACData
  def initialize
    @acl_data = YAML.load_file(Rails.root.join("public", "rbac.yml"))
  end

  def process
    create_groups
    create_roles
    create_policies
  end

  private 
  def create_groups
    current = current_groups
    names = current.collect(&:name)
    group = RBACApiClient::Group.new
    begin
      RBACService.call(RBACApiClient::GroupApi) do |api_instance|
        @acl_data['groups'].each do |grp|
          next if names.include?(grp['name'])
          puts "Creating #{grp['name']}"
          group.name = grp['name']
          group.description = grp['description']
          result = api_instance.create_group(group)
        end
      end
    rescue RBACApiClient::ApiError => e
      puts "Exception when calling GroupApi->create_group: #{e}"
    end
  end

  def current_groups
    RBACService.call(RBACApiClient::GroupApi) do |api|
      RBACService.paginate(api, :list_groups,  {}).to_a
    end
  end

  def create_roles
    current = current_roles
    names = current.collect(&:name)
    role_in = RBACApiClient::RoleIn.new
    begin
      RBACService.call(RBACApiClient::RoleApi) do |api_instance|
        @acl_data['roles'].each do |role|
          next if names.include?(role['name'])
          role_in.name = role['name']
          role_in.access = []
          role['access'].each do |obj|
            access = RBACApiClient::Access.new
            access.permission = obj['permission']
            access.resource_definition = obj['resource_definition'] || []
            role_in.access  << access
          end
          result = api_instance.create_roles(role_in)
          p result
        end
      end
    rescue RBACApiClient::ApiError => e
      puts "Exception when calling RoleApi->create_roles: #{e}"
      raise
    end
  end

  def current_roles
    RBACService.call(RBACApiClient::RoleApi) do |api|
      RBACService.paginate(api, :list_roles,  {}).to_a
    end
  end

  def create_policies
    names = current_policies.collect(&:name)
    groups = current_groups
    roles = current_roles
    policy_in = RBACApiClient::PolicyIn.new
    begin
      RBACService.call(RBACApiClient::RoleApi) do |api_instance|
        @acl_data['policies'].each do |policy|
          next if names.include?(policy['name'])
          policy_in.name = policy['name']
          policy_in.description = policy['description']
          policy_in.group = find_uuid('Group', groups, policy['group']['name'])
          policy_in.roles = [find_uuid('Role', roles, policy['role']['name'])]
          result = api_instance.create_policies(policy_in)
          p result
        end
      end
    rescue RBACApiClient::ApiError => e
      puts "Exception when calling PolicyApi->create_policies: #{e}"
    end
  end

  def current_policies
    RBACService.call(RBACApiClient::PolicyApi) do |api|
      RBACService.paginate(api, :list_policies,  {}).to_a
    end
  end

  def find_uuid(type, data, name)
    result = data.detect { |item| item.name == name }
    raise "#{type} #{name} not found in RBAC service" unless result
    result.uuid
  end
end
