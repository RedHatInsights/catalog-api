module Api
  module V1
    module Mixins
      module RBACMixin
        VALID_RESOURCE_VERBS = %w[create read update delete order].freeze

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
          permission_check('create')
        end

        def resource_check(verb, id = params[:id], klass = controller_name.classify.constantize)
          return unless ManageIQ::API::Common::RBAC::Access.enabled?
          return if ManageIQ::API::Common::RBAC::Roles.assigned_role?('Catalog Administrator')

          ids = access_id_list(verb, klass)
          raise Catalog::NotAuthorized, "#{verb.titleize} access not authorized for #{klass}" if ids.any? && ids.exclude?(id)
        end

        def permission_check(verb, klass = controller_name.classify.constantize)
          return unless ManageIQ::API::Common::RBAC::Access.enabled?

          access_obj = ManageIQ::API::Common::RBAC::Access.new(klass.table_name, verb).process
          raise Catalog::NotAuthorized, "#{verb.titleize} access not authorized for #{klass}" unless access_obj.accessible?
        end

        def role_check(role)
          return unless ManageIQ::API::Common::RBAC::Access.enabled?

          raise Catalog::NotAuthorized unless ManageIQ::API::Common::RBAC::Roles.assigned_role?(role)
        end

        def access_id_list(verb, klass)
          access_obj = ManageIQ::API::Common::RBAC::Access.new(controller_name.classify.constantize.table_name, verb).process
          raise Catalog::NotAuthorized, "#{verb.titleize} access not authorized for #{klass}" unless access_obj.accessible?
          access_obj.id_list
        end
      end
    end
  end
end
