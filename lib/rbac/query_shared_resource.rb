require 'rbac-api-client'
module RBAC
  class QuerySharedResource
    include Utilities
    attr_accessor :share_info

    def initialize(options)
      @app_name = options[:app_name]
      @resource_id = options[:resource_id]
      @resource_name = options[:resource_name]
      @share_info = []
      verbs = options[:verbs]
      @regexp = if verbs
                  Regexp.new("#{@app_name}:#{@resource_name}:(#{verbs.join('|')})")
                else
                  Regexp.new("#{@app_name}:#{@resource_name}:")
                end
      @verb_regexp = Regexp.new("#{@app_name}:#{@resource_name}:(?<verb>.*)")
    end

    def process
      roles_from_policies
      self
    end

    private

    def roles_from_policies
      RBAC::Service.call(RBACApiClient::PolicyApi) do |api_instance|
        RBAC::Service.paginate(api_instance, :list_policies, {}).each do |item|
          filter_roles(item.roles, item.group)
        end
      end
    end

    def filter_roles(roles, group)
      RBAC::Service.call(RBACApiClient::RoleApi) do |api_instance|
        roles.each do |role|
          next unless role.name.end_with?('-Sharing')
          role_obj = api_instance.get_role(role.uuid)
          acls = find_matching_acls(role_obj.access, @resource_id)
          next if acls.empty?
          add_verbs_to_group(group, collect_verbs(acls))
        end
      end
    end

    def collect_verbs(acls)
      acls.collect do |access|
        match = @verb_regexp.match(access.permission)
        match ? match[:verb] : nil
      end.compact
    end

    def add_verbs_to_group(group, verbs)
      result = @share_info.detect { |grp| grp['group_uuid'] == group.uuid }
      if result
        verbs.each { |verb| result['permissions'].add(verb) }
      else
        @share_info << { 'group_uuid' => group.uuid, 'group_name' => group.name, 'permissions' => Set.new(verbs) }
      end
    end
  end
end
