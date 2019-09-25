module RBAC
  class Roles
    attr_reader :roles

    def initialize(prefix = nil, scope = 'principal')
      @roles = {}
      load(prefix, scope)
    end

    def find(name)
      uuid = @roles[name]
      get(uuid) if uuid
    end

    def with_each_role
      @roles.each_value do |uuid|
        yield get(uuid)
      end
    end

    def add(name, acls)
      RBAC::Service.call(RBACApiClient::RoleApi) do |api_instance|
        role_in = RBACApiClient::RoleIn.new
        role_in.name = name
        role_in.access = acls
        api_instance.create_roles(role_in).tap do |role|
          @roles[name] = role.uuid
        end
      end
    end

    def update(role)
      RBAC::Service.call(RBACApiClient::RoleApi) do |api_instance|
        api_instance.update_role(role.uuid, role)
      end
    end

    def delete(role)
      @roles.delete(role.name)
      RBAC::Service.call(RBACApiClient::RoleApi) do |api_instance|
        api_instance.delete_role(role.uuid)
      end
    end

    def self.assigned_role?(role_name)
      opts = { :name  => role_name,
               :scope => 'principal' }

      RBAC::Service.call(RBACApiClient::RoleApi) do |api_instance|
        RBAC::Service.paginate(api_instance, :list_roles, opts).count.positive?
      end
    end

    private

    def load(prefix, scope)
      opts = { :scope => scope, :name => prefix, :limit => 500 }
      RBAC::Service.call(RBACApiClient::RoleApi) do |api_instance|
        RBAC::Service.paginate(api_instance, :list_roles, opts).each do |role|
          @roles[role.name] = role.uuid
        end
      end
    end

    def get(uuid)
      RBAC::Service.call(RBACApiClient::RoleApi) do |api_instance|
        api_instance.get_role(uuid)
      end
    end
  end
end
