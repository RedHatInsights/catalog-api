module Api
  module V1x1
    module Catalog
      class PortfolioItemOrderable
        attr_reader :result
        attr_reader :messages

        def initialize(portfolio_item)
          @portfolio_item = portfolio_item
          @messages = []
        end

        def process
          fetch_source
          fetch_service_offering
          @result = @service_offering && @source && !archived? && !survey_changed? && source_available?
          @result = !!@result
          self
        end

        private

        def source_available?
          @source&.availability_status == "available"
        end

        def archived?
          @service_offering.archived_at.present?.tap do |response|
            @messages << "Service offering archived for Portfolio Item #{@portfolio_item.name}"
            Rails.logger.debug("Service offering archived for Portfolio Item #{@portfolio_item.name}")
          end
        end

        def survey_changed?
          ::Catalog::SurveyCompare.any_changed?(@portfolio_item.service_plans).tap do |response|
            @messages << "Survey Changed for Portfolio Item #{@portfolio_item.name}"
            Rails.logger.debug("Survey Changed for Portfolio Item #{@portfolio_item.name}")
          end
        end

        def fetch_source
          @soure = CatalogInventory::Service.call(CatalogInventoryApiClient::SourceApi) do |api|
            api.show_source(@portfolio_item.service_offering_source_ref)
          end
        rescue StandardError => e
          Rails.logger.error("Source could not be retrieved for Portfolio Item #{@portfolio_item.name}")
          Rails.logger.error(e.message)
          @messages << "Source could not be retrieved for Portfolio Item #{@portfolio_item.name}"
        end

        def fetch_service_offering
          @service_offering = CatalogInventory::Service.call(CatalogInventoryApiClient::ServiceOfferingApi) do |api|
            api.show_service_offering(@portfolio_item.service_offering_ref)
          end
        rescue StandardError => e
          Rails.logger.error("Service offering could not be retrieved for Portfolio Item #{@portfolio_item.name}")
          Rails.logger.error(e.message)
          @messages << "Service offering could not be retrieved for Portfolio Item #{@portfolio_item.name}"
        end
      end
    end
  end
end
