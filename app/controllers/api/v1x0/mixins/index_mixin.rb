module Api
  module V1x0
    module Mixins
      module IndexMixin
        def scoped(relation)
          #relation = rbac_scope(relation) if RBAC::Access.enabled?
          if relation.model.respond_to?(:taggable?) && relation.model.taggable?
            ref_schema = {relation.model.tagging_relation_name => :tag}

            relation = relation.includes(ref_schema).references(ref_schema)
          end
          relation
        end

        def collection(base_query)
          render :json => ManageIQ::API::Common::PaginatedResponse.new(
            :base_query => scoped(base_query),
            :request    => request,
            :limit      => params.permit(:limit)[:limit],
            :offset     => params.permit(:offset)[:offset]
          ).response
        end

        def rbac_scope(relation)
          access_obj = RBAC::Access.new(relation.model.table_name, 'read').process
          raise Catalog::NotAuthorized, "Not Authorized for #{relation.model}" unless access_obj.accessible?
          ids = access_obj.id_list
          ids.any? ? relation.where(:id => ids) : relation
        end
      end
    end
  end
end
