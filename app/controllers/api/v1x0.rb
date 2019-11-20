module Api
  module V1x0
    class RootController < ApplicationController
      def openapi
        render :json => Api::Docs["1.0"]
      end
    end

    class ApprovalRequestsController          < Api::V1::ApprovalRequestsController; end
    class GraphqlController                   < Api::V1::GraphqlController; end
    class IconsController                     < Api::V1::IconsController; end
    class OrderItemsController                < Api::V1::OrderItemsController; end
    class OrdersController                    < Api::V1::OrdersController; end
    class PortfoliosController                < Api::V1::PortfoliosController; end
    class PortfolioItemsController            < Api::V1::PortfolioItemsController; end
    class ProgressMessagesController          < Api::V1::ProgressMessagesController; end
    class ProviderControlParametersController < Api::V1::ProviderControlParametersController; end
    class ServicePlansController              < Api::V1::ServicePlansController; end
    class SettingsController                  < Api::V1::SettingsController; end
    class TagsController                      < Api::V1::TagsController; end
    class TenantsController                   < Api::V1::TenantsController; end
  end
end
