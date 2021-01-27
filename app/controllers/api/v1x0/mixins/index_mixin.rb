module Api
  module V1x0
    module Mixins
      module IndexMixin
        def scoped(relation, pre_authorized)
          relation = rbac_scope(relation, :pre_authorized => pre_authorized) if ::Insights::API::Common::RBAC::Access.enabled?
          if relation.model.respond_to?(:taggable?) && relation.model.taggable?
            ref_schema = {relation.model.tagging_relation_name => :tag}

            relation = relation.includes(ref_schema).references(ref_schema)
          end
          relation
        end

        def collection(base_query, pre_authorized: false)
          render :json => Insights::API::Common::PaginatedResponse.new(
            :base_query => filtered(scoped(base_query, pre_authorized)),
            :request    => request,
            :limit      => pagination_limit,
            :offset     => pagination_offset
          ).response
        end

        def rbac_scope(relation, pre_authorized: false)
          return relation if pre_authorized

          policy_scope(relation)
        end

        def filtered(base_query)
          Insights::API::Common::Filter.new(base_query, params[:filter], api_doc_definition).apply
        end

        private

        def api_doc_definition
          @api_doc_definition ||= Api::Docs[api_version].definitions[model_name]
        end

        def api_version
          @api_version ||= name.split("::")[1].downcase.delete("v").sub("x", ".")
        end

        def model_name
          @model_name ||= controller_name.classify
        end

        def name
          self.class.to_s
        end

        def permitted_params
          super + [:messageable_type, :messageable_id]
        end
      end
    end
  end
end
