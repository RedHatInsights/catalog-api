require 'services/api/v1x1'
require 'controllers/api/v1x1'

module Api
  module V1x2
    class RootController < ApplicationController
      def openapi
        render :json => Api::Docs["1.2"]
      end
    end

    class ApprovalRequestsController          < Api::V1x1::ApprovalRequestsController; end
    class GraphqlController                   < Api::V1x1::GraphqlController; end
    class IconsController                     < Api::V1x1::IconsController; end
    class OrderItemsController                < Api::V1x1::OrderItemsController; end
    class OrdersController                    < Api::V1x1::OrdersController; end
    class PortfolioItemsController            < Api::V1x1::PortfolioItemsController; end
    class PortfoliosController                < Api::V1x1::PortfoliosController; end
    class ProgressMessagesController          < Api::V1x1::ProgressMessagesController; end
    class ProviderControlParametersController < Api::V1x1::ProviderControlParametersController; end
    class ServicePlansController              < Api::V1x1::ServicePlansController; end
    class SettingsController                  < Api::V1x1::SettingsController; end
    class TagsController                      < Api::V1x1::TagsController; end
    class TenantsController                   < Api::V1x1::TenantsController; end

    extend_each_subclass Mixins::IndexMixin
  end
end
