module Api
  module V1x0
    module Catalog
      class PortfolioItemOrderable
        attr_reader :result

        def initialize(portfolio_item)
          @result = false
          @portfolio_item = portfolio_item
        end

        def process
          @result = !archived? && !survey_changed? && source_available?
          self
        end

        private

        def source_available?
          source.availability_status == "available"
        end

        def archived?
          service_offering.archived_at.present?.tap do |response|
            Rails.logger.debug("Service offering archived for Portfolio Item #{@portfolio_item.name}")
          end
        end

        def survey_changed?
          ::Catalog::SurveyCompare.any_changed?(@portfolio_item.service_plans).tap do |response|
            Rails.logger.debug("Survey Changed for Portfolio Item #{@portfolio_item.name}")
          end
        end

        def source
          @source ||= Sources.call do |api_instance|
            api_instance.show_source(@portfolio_item.service_offering_source_ref)
          end
        end

        def service_offering
          @service_offering ||= TopologicalInventory.call do |api|
            api.show_service_offering(@portfolio_item.service_offering_ref)
          end
        end
      end
    end
  end
end
