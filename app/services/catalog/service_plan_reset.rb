module Catalog
  class ServicePlanReset
    attr_reader :status

    def initialize(service_plan_id)
      @plan = ServicePlan.find(service_plan_id)
    end

    def process
      @status = if @plan.modified.nil?
                  :no_content
                else
                  :ok
                end

      reimport_from_topo
      self
    rescue StandardError => e
      Rails.logger.error("Service Plans #{e.message}")
      raise
    end

    private

    def reimport_from_topo
      Catalog::ImportServicePlans.new(@plan.portfolio_item_id, true).process
    end
  end
end
