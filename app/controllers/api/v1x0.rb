require 'manageiq-api-common'
module Api
  module V1x0
    class RootController < ApplicationController
      def openapi
        render :json => Api::Docs["1.0"]
      end
    end

    class GraphqlController < Api::V1::GraphqlController; end
  end
end
