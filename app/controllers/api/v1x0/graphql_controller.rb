require "insights/api/common/graphql"

module Api
  module V1x0
    class GraphqlController < ApplicationController
      include Api::V1x0::Mixins::IndexMixin

      def overlay
        {
          "^.*$" => {
            "base_query" => lambda do |model_class, _args, _ctx|
              Insights::API::Common::RBAC::Access.enabled? ? rbac_scope(model_class.all) : model_class
            end
          }
        }
      end

      def query
        graphql_api_schema = ::Insights::API::Common::GraphQL::Generator.init_schema(request, overlay)
        variables = ::Insights::API::Common::GraphQL.ensure_hash(params[:variables])
        result = graphql_api_schema.execute(
          params[:query],
          :variables => variables
        )
        render :json => result
      end
    end
  end
end
