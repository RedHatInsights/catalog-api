module RBAC
  class Roles
    def initialize(prefix)
      @roles = {}
      load_roles(prefix)
      @deleted_roles = SortedSet.new
    end

    def find_role_by_name(name)
      uuid = @roles[name]
      get_role(uuid) if uuid
    end

    def with_each_role
      @roles.each_value do |uuid|
        yield get_role(uuid)
      end
    end

    def add_role(name, acls)
      RBAC::Service.call(RBACApiClient::RoleApi) do |api_instance|
        role_in = RBACApiClient::RoleIn.new
        role_in.name = name
        role_in.access = acls
        api_instance.create_roles(role_in)
      end
    end

    def update_role(role)
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

    private

    def load_roles(prefix)
      opts = { :limit => 100,
               :name  => prefix }
      RBAC::Service.call(RBACApiClient::RoleApi) do |api_instance|
        RBAC::Service.paginate(api_instance, :list_roles, opts).each do |role|
          @roles[role.name] = role.uuid
        end
      end
    end

    def get_role(uuid)
      raise ArgumentError, "Role object #{uuid} has been deleted" if @deleted_roles.include?(uuid)
      RBAC::Service.call(RBACApiClient::RoleApi) do |api_instance|
        api_instance.get_role(uuid)
      end
    end
  end
end
