require 'services/api/v1x3'
require 'controllers/api/v1x2'

module Api
  module V1x3
    class RootController < ApplicationController
      def openapi
        render :json => Api::Docs["1.3"]
      end
    end

    class ApprovalRequestsController          < Api::V1x2::ApprovalRequestsController; end
    class GraphqlController                   < Api::V1x2::GraphqlController; end
    class IconsController                     < Api::V1x2::IconsController; end
    class OrderItemsController                < Api::V1x2::OrderItemsController; end
    class OrdersController                    < Api::V1x2::OrdersController; end
    class PortfoliosController                < Api::V1x2::PortfoliosController; end
    class PortfolioItemsController            < Api::V1x2::PortfolioItemsController; end
    class ProviderControlParametersController < Api::V1x2::ProviderControlParametersController; end
    class ServicePlansController              < Api::V1x2::ServicePlansController; end
    class SettingsController                  < Api::V1x2::SettingsController; end
    class TagsController                      < Api::V1x2::TagsController; end
    class TenantsController                   < Api::V1x2::TenantsController; end

    extend_each_subclass Mixins::IndexMixin
  end
end
