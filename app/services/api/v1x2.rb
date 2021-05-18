require 'services/api/v1x1'

module Api
  module V1x2
    module Catalog
      class AddToOrder                          < Api::V1x1::Catalog::AddToOrder; end
      class CancelOrder                         < Api::V1x1::Catalog::CancelOrder; end
      class CopyPortfolio                       < Api::V1x1::Catalog::CopyPortfolio; end
      class CopyPortfolioItem                   < Api::V1x1::Catalog::CopyPortfolioItem; end
      class CreateIcon                          < Api::V1x1::Catalog::CreateIcon; end
      class CreateRequestForAppliedInventories  < Api::V1x1::Catalog::CreateRequestForAppliedInventories; end
      class DuplicateImage                      < Api::V1x1::Catalog::DuplicateImage; end
      class ImportServicePlans                  < Api::V1x1::Catalog::ImportServicePlans; end
      class NextName                            < Api::V1x1::Catalog::NextName; end
      class PortfolioItemOrderable              < Api::V1x1::Catalog::PortfolioItemOrderable; end
      class ProviderControlParameters           < Api::V1x1::Catalog::ProviderControlParameters; end
      class ServiceOffering                     < Api::V1x1::Catalog::ServiceOffering; end
      class ServicePlanCompare                  < Api::V1x1::Catalog::ServicePlanCompare; end
      class ServicePlanJson                     < Api::V1x1::Catalog::ServicePlanJson; end
      class ServicePlanReset                    < Api::V1x1::Catalog::ServicePlanReset; end
      class ServicePlans                        < Api::V1x1::Catalog::ServicePlans; end
      class ShareInfo                           < Api::V1x1::Catalog::ShareInfo; end
      class ShareResource                       < Api::V1x1::Catalog::ShareResource; end
      class SoftDelete                          < Api::V1x1::Catalog::SoftDelete; end
      class SoftDeleteRestore                   < Api::V1x1::Catalog::SoftDeleteRestore; end
      class TenantSettings                      < Api::V1x1::Catalog::TenantSettings; end
      class UnshareResource                     < Api::V1x1::Catalog::UnshareResource; end
      class UpdateIcon                          < Api::V1x1::Catalog::UpdateIcon; end
      class ValidateSource                      < Api::V1x1::Catalog::ValidateSource; end
    end

    module ServiceOffering
      class AddToPortfolioItem < Api::V1x1::ServiceOffering::AddToPortfolioItem; end
    end
  end
end
