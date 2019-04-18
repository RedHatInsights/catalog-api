module Api
  module V1x0
    module Mixins
      module RBACMixin
        def write_access_check
          return unless RBAC::Access.enabled?
          access_obj = RBAC::Access.new(controller_name.classify.constantize.table_name, 'write').process
          raise Catalog::NotAuthorized, "Write access not authorized for #{controller_name.classify.constantize}" unless access_obj.accessible?
          ids = access_obj.id_list
          raise Catalog::NotAuthorized, "Write access not authorized for #{controller_name.classify.constantize}" if ids.any? && ids.exclude?(params[:id])
        end
      end
    end
  end
end
