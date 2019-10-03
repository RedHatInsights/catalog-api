module Api
  module V1x0
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

        def permission_array_check(permissions)
          invalid_parameter('Permission should be an array') unless permissions.kind_of?(Array)
        end

        def role_check(role)
          return unless RBAC::Access.enabled?

          raise Catalog::NotAuthorized unless RBAC::Roles.assigned_role?(role)
        end

        private

        def permission_format_check(permissions)
          permissions.each do |perm|
            invalid_parameter("Permission should be : delimited and contain app_name:resource:verb, where verb has to be one of #{VALID_RESOURCE_VERBS}") unless perm.kind_of?(String)
            perm_list = perm.split(':')
            invalid_parameter("Permission should be : delimited and contain app_name:resource:verb, where verb has to be one of #{VALID_RESOURCE_VERBS}") unless perm_list.length == 3
            invalid_parameter("Permission app_name should be catalog") unless perm_list.first == 'catalog'
            invalid_parameter("Only #{controller_name} objects can be shared") unless perm_list[1] == controller_name
            invalid_parameter("Verbs should be one of #{VALID_RESOURCE_VERBS}") unless VALID_RESOURCE_VERBS.include?(perm_list[2])
          end
        end

        def invalid_parameter(str)
          raise Catalog::InvalidParameter, str
        end
      end
    end
  end
end
