require 'services/api/v1x2'

module Api
  module V1x3
    module Catalog
      class AddToOrder                          < Api::V1x2::Catalog::AddToOrder; end
      class AddToOrderViaOrderProcess           < Api::V1x2::Catalog::AddToOrderViaOrderProcess; end
      class CancelOrder                         < Api::V1x2::Catalog::CancelOrder; end
      class CopyPortfolio                       < Api::V1x2::Catalog::CopyPortfolio; end
      class CopyPortfolioItem                   < Api::V1x2::Catalog::CopyPortfolioItem; end
      class CreateIcon                          < Api::V1x2::Catalog::CreateIcon; end
      class CreateRequestForAppliedInventories  < Api::V1x2::Catalog::CreateRequestForAppliedInventories; end
      class DuplicateImage                      < Api::V1x2::Catalog::DuplicateImage; end
      class GetLinkedOrderProcess               < Api::V1x2::Catalog::GetLinkedOrderProcess; end
      class ImportServicePlans                  < Api::V1x2::Catalog::ImportServicePlans; end
      class LinkToOrderProcess                  < Api::V1x2::Catalog::LinkToOrderProcess; end
      class NextName                            < Api::V1x2::Catalog::NextName; end
      class OrderProcessAssociator              < Api::V1x2::Catalog::OrderProcessAssociator; end
      class OrderProcessDissociator             < Api::V1x2::Catalog::OrderProcessDissociator; end
      class PortfolioItemOrderable              < Api::V1x2::Catalog::PortfolioItemOrderable; end
      class ProviderControlParameters           < Api::V1x2::Catalog::ProviderControlParameters; end
      class ServiceOffering                     < Api::V1x2::Catalog::ServiceOffering; end
      class ServicePlanCompare                  < Api::V1x2::Catalog::ServicePlanCompare; end
      class ServicePlanJson                     < Api::V1x2::Catalog::ServicePlanJson; end
      class ServicePlanReset                    < Api::V1x2::Catalog::ServicePlanReset; end
      class ServicePlans                        < Api::V1x2::Catalog::ServicePlans; end
      class ShareInfo                           < Api::V1x2::Catalog::ShareInfo; end
      class ShareResource                       < Api::V1x2::Catalog::ShareResource; end
      class SoftDelete                          < Api::V1x2::Catalog::SoftDelete; end
      class SoftDeleteRestore                   < Api::V1x2::Catalog::SoftDeleteRestore; end
      class TaggingService                      < Api::V1x2::Catalog::TaggingService; end
      class TenantSettings                      < Api::V1x2::Catalog::TenantSettings; end
      class UnlinkFromOrderProcess              < Api::V1x2::Catalog::UnlinkFromOrderProcess; end
      class UnshareResource                     < Api::V1x2::Catalog::UnshareResource; end
      class UpdateIcon                          < Api::V1x2::Catalog::UpdateIcon; end
      class ValidateSource                      < Api::V1x2::Catalog::ValidateSource; end
    end

    module ServiceOffering
      class AddToPortfolioItem < Api::V1x2::ServiceOffering::AddToPortfolioItem; end
    end
  end
end
