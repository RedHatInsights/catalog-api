module Catalog
  module RBAC
    class Role
      ADMINISTRATOR_ROLE_NAME = 'Catalog Administrator'.freeze

      def self.catalog_administrator?
        Insights::API::Common::RBAC::Roles.assigned_role?(ADMINISTRATOR_ROLE_NAME)
      end

      def self.role_check(role)
        return unless Insights::API::Common::RBAC::Access.enabled?

        raise Catalog::NotAuthorized unless Insights::API::Common::RBAC::Roles.assigned_role?(role)
      end
    end
  end
end
