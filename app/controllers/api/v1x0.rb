module Api
  module V1x0
    class RootController < ApplicationController
      def openapi
        render :json => Api::Docs["1.0"]
      end
    end
  end
end
