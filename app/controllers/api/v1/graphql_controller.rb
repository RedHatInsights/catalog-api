require "manageiq/api/common/graphql"

module Api
  module V1
    class GraphqlController < ApplicationController
      include Api::V1x0::Mixins::IndexMixin

      def overlay
        {
          "^.*$" => {
            "base_query" => lambda do |model_class, _ctx|
              RBAC::Access.enabled? ? rbac_scope(model_class.all) : model_class.all 
            end
          }
        }
      end

      def query
        graphql_api_schema = ::ManageIQ::API::Common::GraphQL::Generator.init_schema(request, overlay)
        variables = ::ManageIQ::API::Common::GraphQL.ensure_hash(params[:variables])
        result = graphql_api_schema.execute(
          params[:query],
          :variables => variables
        )
        render :json => result
      end
    end
  end
end
