module Catalog
  class SurveyCompare
    attr_reader :base
    class << self
      def changed?(plan)
        return false if empty?(plan)
        potential = new(plan)
        potential.inventory_base != potential.base
      end

      def any_changed?(plans)
        plans.any? { |plan| changed?(plan) }
      end

      def collect_changed(plans)
        plans.collect { |plan| plan if changed?(plan) }.compact
      end

      def empty?(plan)
        plan.empty_schema?
      end
    end

    def initialize(plan)
      @base = plan.base.deep_stringify_keys
      @reference = plan.portfolio_item.service_offering_ref
    end

    def inventory_base
      CatalogInventory::Service.call(CatalogInventoryApiClient::ServiceOfferingApi) do |api_instance|
        survey = api_instance.list_service_offering_service_plans(@reference)
        survey.data.first.create_json_schema.deep_stringify_keys
      end
    end
  end
end
