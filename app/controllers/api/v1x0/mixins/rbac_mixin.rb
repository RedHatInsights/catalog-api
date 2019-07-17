module Api
  module V1x0
    module Mixins
      module RBACMixin
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

        def permission_array_check(verbs)
          return unless RBAC::Access.enabled?

          if !verbs.kind_of?(Array)
            invalid_parameter('Permission should be an array')
          elsif !verbs.all? { |verb| verb.kind_of?(String) }
            invalid_parameter('Permissions should all be strings')
          elsif verbs.blank?
            invalid_parameter('Permissions should not be empty')
          end
        end

        private

        def invalid_parameter(str)
          raise Catalog::InvalidParameter, str
        end
      end
    end
  end
end
