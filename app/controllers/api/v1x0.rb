module Api
  module V1x0
    class RootController < ApplicationController
      def openapi
        render :json => Rails.root.join('public', 'doc', 'openapi-3-v1.0.0.json').read
      end
    end
  end
end
