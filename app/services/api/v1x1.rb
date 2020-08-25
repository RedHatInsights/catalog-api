require 'services/api/v1x0'
module Api
  module V1x1
    module Catalog
      class AddToOrder                          < Api::V1x0::Catalog::AddToOrder; end
      class CancelOrder                         < Api::V1x0::Catalog::CancelOrder; end
      class CopyPortfolio                       < Api::V1x0::Catalog::CopyPortfolio; end
      class CopyPortfolioItem                   < Api::V1x0::Catalog::CopyPortfolioItem; end
      class CreateIcon                          < Api::V1x0::Catalog::CreateIcon; end
      class CreateRequestForAppliedInventories  < Api::V1x0::Catalog::CreateRequestBodyFrom; end
      class DuplicateImage                      < Api::V1x0::Catalog::DuplicateImage; end
      class ImportServicePlans                  < Api::V1x0::Catalog::ImportServicePlans; end
      class NextName                            < Api::V1x0::Catalog::NextName; end
      class ProviderControlParameters           < Api::V1x0::Catalog::ProviderControlParameters; end
      class ServiceOffering                     < Api::V1x0::Catalog::ServiceOffering; end
      class ServicePlanCompare                  < Api::V1x0::Catalog::ServicePlanCompare; end
      class ServicePlanJson                     < Api::V1x0::Catalog::ServicePlanJson; end
      class ServicePlans                        < Api::V1x0::Catalog::ServicePlans; end
      class ShareInfo                           < Api::V1x0::Catalog::ShareInfo; end
      class ShareResource                       < Api::V1x0::Catalog::ShareResource; end
      class SoftDelete                          < Api::V1x0::Catalog::SoftDelete; end
      class SoftDeleteRestore                   < Api::V1x0::Catalog::SoftDeleteRestore; end
      class TenantSettings                      < Api::V1x0::Catalog::TenantSettings; end
      class UnshareResource                     < Api::V1x0::Catalog::UnshareResource; end
      class UpdateIcon                          < Api::V1x0::Catalog::UpdateIcon; end
      class ValidateSource                      < Api::V1x0::Catalog::ValidateSource; end
    end

    module Group
      class Seed < Api::V1x0::Group::Seed; end
    end

    module ServiceOffering
      class AddToPortfolioItem < Api::V1x0::ServiceOffering::AddToPortfolioItem; end
    end
  end
end
