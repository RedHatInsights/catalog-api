module Api
  module V1x0
    module Catalog
      class ServicePlanCompare
        attr_reader :service_plan

        def initialize(service_plan_id)
          @service_plan = ServicePlan.find(service_plan_id)
        end

        def process
          raise ::Catalog::InvalidSurvey, @service_plan.invalid_survey_message if survey_changed?

          self
        end

        private

        def survey_changed?
          ::Catalog::SurveyCompare.changed?(@service_plan)
        end
      end
    end
  end
end
