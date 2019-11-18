module Catalog
  class ServicePlanJson
    include JsonSchemaReader

    def initialize(opts)
      if opts.key?(:service_plan_id)
        @service_plans = ServicePlan.where(:id => opts[:service_plan_id])
      elsif opts.key?(:portfolio_item_id)
        @service_plans = ServicePlan.where(:portfolio_item_id => opts[:portfolio_item_id])
      end

      @opts = opts
      @json = []
    end

    def process
      relevant_service_plans.each do |plan|
        @reference = plan.portfolio_item.service_offering_ref
        @portfolio_item_id = plan.portfolio_item.id
        @service_plan = OpenStruct.new(
          :id                 => plan.id,
          :create_json_schema => plan.send(@opts[:schema] || "modified"),
          :name               => plan.name,
          :description        => plan.description
        )

        @json << read_json_schema("service_plan.erb")
      end

      self
    end

    def json
      @opts[:collection] ? @json : @json.first
    end

    private

    def relevant_service_plans
      @opts[:collection] ? @service_plans : [@service_plans.first]
    end
  end
end
