module Api
  module V0x1
    module Mixins
      module IndexMixin
        def scoped(relation)
          access_obj = ServiceCatalog::RBACAccess.new(relation.model.table_name, 'read').process
          raise ServiceCatalog::NotAuthorized.new('Not Authorized') unless access_obj.accessible?
          ids = access_obj.id_list
          relation = relation.where(:id => ids) if ids.any?
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
      end
    end
  end
end
