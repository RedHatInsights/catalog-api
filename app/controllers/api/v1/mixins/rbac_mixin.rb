module Api
  module V1
    module Mixins
      module RBACMixin
        VALID_RESOURCE_VERBS = %w[create read update delete order].freeze
        ADMINISTRATOR_ROLE_NAME = 'Catalog Administrator'.freeze

        def update_access_check
          resource_check('update')
        end

        def read_access_check
          resource_check('read')
        end

        def create_access_check
          permission_check('create')
        end

        def delete_access_check
          permission_check('delete')
        end

        def resource_check(verb, id = params[:id], klass = controller_name.classify.constantize)
          return unless Insights::API::Common::RBAC::Access.enabled?
          return if catalog_administrator?

          ids = access_id_list(verb, klass)
          if klass.respond_to?(:aceable?) && klass.aceable?
            raise Catalog::NotAuthorized, "#{verb.titleize} access not authorized for #{klass}" if ids.any? && ids.exclude?(id)
          end
        end

        def permission_check(verb, klass = controller_name.classify.constantize)
          return unless Insights::API::Common::RBAC::Access.enabled?

          access_obj = Insights::API::Common::RBAC::Access.new(klass.table_name, verb).process
          raise Catalog::NotAuthorized, "#{verb.titleize} access not authorized for #{klass}" unless access_obj.accessible?
        end

        def role_check(role)
          return unless Insights::API::Common::RBAC::Access.enabled?

          raise Catalog::NotAuthorized unless Insights::API::Common::RBAC::Roles.assigned_role?(role)
        end

        def catalog_administrator?
          Insights::API::Common::RBAC::Roles.assigned_role?(ADMINISTRATOR_ROLE_NAME)
        end

        def access_id_list(verb, klass)
          access_obj = Insights::API::Common::RBAC::Access.new(controller_name.classify.constantize.table_name, verb).process
          raise Catalog::NotAuthorized, "#{verb.titleize} access not authorized for #{klass}" unless access_obj.accessible?

          ace_ids(verb, klass)
        end
      end
    end
  end
end
