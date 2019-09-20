require "manageiq/api/common/graphql"

module Api
  class GraphqlController < ApplicationController
    skip_before_action :validate_request
    skip_before_action :validate_primary_collection_id

    def query
      graphql_api_schema = ::ManageIQ::API::Common::GraphQL::Generator.init_schema(request)
      variables = ::ManageIQ::API::Common::GraphQL.ensure_hash(params[:variables])
      result = graphql_api_schema.execute(
        params[:query],
        :variables => variables
      )
      render :json => result
    end
  end
end
