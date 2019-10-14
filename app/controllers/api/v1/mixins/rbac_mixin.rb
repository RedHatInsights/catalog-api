module Api
  module V1
    module Mixins
      module RBACMixin
        VALID_RESOURCE_VERBS = %w[read write order].freeze

        def write_access_check
          resource_check('write')
        end

        def read_access_check
          resource_check('read')
        end

        def resource_check(verb, id = params[:id], klass = controller_name.classify.constantize)
          return unless RBAC::Access.enabled?
          access_obj = RBAC::Access.new(controller_name.classify.constantize.table_name, verb).process
          raise Catalog::NotAuthorized, "#{verb.titleize} access not authorized for #{klass}" unless access_obj.accessible?
          ids = access_obj.id_list
          raise Catalog::NotAuthorized, "#{verb.titleize} access not authorized for #{klass}" if ids.any? && ids.exclude?(id)
        end

        def permission_check(verb, klass = controller_name.classify.constantize)
          return unless RBAC::Access.enabled?

          access_obj = RBAC::Access.new(klass.table_name, verb).process
          raise Catalog::NotAuthorized, "#{verb.titleize} access not authorized for #{klass}" unless access_obj.accessible?
        end

        def role_check(role)
          return unless RBAC::Access.enabled?

          raise Catalog::NotAuthorized unless RBAC::Roles.assigned_role?(role)
        end
      end
    end
  end
end
