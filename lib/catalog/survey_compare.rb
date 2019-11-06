module Catalog
  class SurveyCompare
    attr_reader :base
    class << self
      def changed?(plan)
        potential = new(plan)
        encoded_base = Base64.strict_encode64(potential.base.to_json)
        encoded_topo = Base64.strict_encode64(potential.topo_base.to_json)
        encoded_topo != encoded_base
      end
    end

    def initialize(plan)
      @base = plan.base
      @reference = plan.portfolio_item.service_offering_ref
    end

    def topo_base
      TopologicalInventory.call do |api_instance|
        survey = api_instance.list_service_offering_service_plans(@reference)
        survey.data.first.create_json_schema
      end
    end
  end
end
