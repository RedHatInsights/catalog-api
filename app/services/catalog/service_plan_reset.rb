module Catalog
  class ServicePlanReset
    attr_reader :status

    def initialize(service_plan_id)
      @service_plan_id = service_plan_id
    end

    def process
      plan = ServicePlan.find(@service_plan_id)

      if plan.modified.nil?
        @status = :no_content
      else
        plan.update!(:modified => nil)
        @status = :ok
      end

      self
    rescue StandardError => e
      Rails.logger.error("Service Plans #{e.message}")
      raise
    end
  end
end
