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
          @source = fetch_resource(CatalogInventoryApiClient::SourceApi, :show_source, @portfolio_item.service_offering_source_ref)
          @service_offering = fetch_resource(CatalogInventoryApiClient::ServiceOfferingApi, :show_service_offering, @portfolio_item.service_offering_ref)
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

        def fetch_resource(klass, method, resource_ref)
          CatalogInventory::Service.call(klass) do |api|
            api.send(method.to_sym, resource_ref)
          end
        rescue StandardError => e
          Rails.logger.error("#{klass}:#{method} could not retrieve for #{resource_ref}")
          Rails.logger.error(e.message)
          @messages << "#{klass}:#{method} could not retrieve for #{resource_ref}"
          nil
        end
      end
    end
  end
end
