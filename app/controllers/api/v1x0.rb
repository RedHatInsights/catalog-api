module Api
  module V1x0
    class RootController < ApplicationController
      def openapi
        render :json => Rails.root.join('public', 'catalog', 'v1.0.0', 'openapi.json').read
      end
    end
  end
end
