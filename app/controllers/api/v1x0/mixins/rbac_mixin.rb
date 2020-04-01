module Api
  module V1x0
    module Mixins
      module RBACMixin
        VALID_RESOURCE_VERBS = %w[create read update delete order].freeze
        ADMINISTRATOR_ROLE_NAME = 'Catalog Administrator'.freeze

        def role_check(role)
          return unless Insights::API::Common::RBAC::Access.enabled?

          raise Catalog::NotAuthorized unless Insights::API::Common::RBAC::Roles.assigned_role?(role)
        end
      end
    end
  end
end
