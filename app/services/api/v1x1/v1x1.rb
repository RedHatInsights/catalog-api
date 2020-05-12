module Api
  module V1x1
    module Catalog
      class AddToOrder                          < Api::V1x0::Catalog::AddToOrder; end
      class ApprovalTransition                  < Api::V1x0::Catalog::ApprovalTransition; end
      class CancelOrder                         < Api::V1x0::Catalog::CancelOrder; end
      class CopyPortfolio                       < Api::V1x0::Catalog::CopyPortfolio; end
      class CopyPortfolioItem                   < Api::V1x0::Catalog::CopyPortfolioItem; end
      class CreateApprovalRequest               < Api::V1x0::Catalog::CreateApprovalRequest; end
      class CreateIcon                          < Api::V1x0::Catalog::CreateIcon; end
      class CreateRequestBodyFrom               < Api::V1x0::Catalog::CreateRequestBodyFrom; end
      class CreateRequestForAppliedInventories  < Api::V1x0::Catalog::CreateRequestBodyFrom; end
      class DetermineTaskRelevancy              < Api::V1x0::Catalog::DetermineTaskRelevancy; end
      class DuplicateImage                      < Api::V1x0::Catalog::DuplicateImage; end
      class ImportServicePlans                  < Api::V1x0::Catalog::ImportServicePlans; end
      class NextName                            < Api::V1x0::Catalog::NextName; end
      class NotifyApprovalRequest               < Api::V1x0::Catalog::NotifyApprovalRequest; end
      class OrderItemSanitizedParameters        < Api::V1x0::Catalog::OrderItemSanitizedParameters; end
      class ProviderControlParameters           < Api::V1x0::Catalog::ProviderControlParameters; end
      class ServiceOffering                     < Api::V1x0::Catalog::ServiceOffering; end
      class ServicePlanCompare                  < Api::V1x0::Catalog::ServicePlanCompare; end
      class ServicePlanJson                     < Api::V1x0::Catalog::ServicePlanJson; end
      class ServicePlanReset                    < Api::V1x0::Catalog::ServicePlanReset; end
      class ServicePlans                        < Api::V1x0::Catalog::ServicePlans; end
      class ShareInfo                           < Api::V1x0::Catalog::ShareInfo; end
      class ShareResource                       < Api::V1x0::Catalog::ShareResource; end
      class SoftDelete                          < Api::V1x0::Catalog::SoftDelete; end
      class SoftDeleteRestore                   < Api::V1x0::Catalog::SoftDeleteRestore; end
      class SubmitOrder                         < Api::V1x0::Catalog::SubmitOrder; end
      class TenantSettings                      < Api::V1x0::Catalog::TenantSettings; end
      class UnshareResource                     < Api::V1x0::Catalog::UnshareResource; end
      class UpdateIcon                          < Api::V1x0::Catalog::UpdateIcon; end
      class UpdateOrderItem                     < Api::V1x0::Catalog::UpdateOrderItem; end
      class ValidateSource                      < Api::V1x0::Catalog::ValidateSource; end
    end

    module Group
      class Seed < Api::V1x0::Group::Seed; end
    end

    module ServiceOffering
      class AddToPortfolioItem < Api::V1x0::ServiceOffering::AddToPortfolioItem; end
    end

    module Tags
      class CollectLocalOrderResources < Api::V1x0::Tags::CollectLocalOrderResources; end
      module Topology
        class RemoteInventory < Api::V1x0::Tags::Topology::RemoteInventory; end
      end
    end
  end
end
