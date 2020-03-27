module Catalog
  class ServicePlanJson
    include JsonSchemaReader

    def initialize(opts)
      if opts.key?(:service_plan_id)
        @service_plans = ServicePlan.where(:id => opts[:service_plan_id])
      elsif opts.key?(:portfolio_item_id)
        @service_plans = ServicePlan.where(:portfolio_item_id => opts[:portfolio_item_id])
      elsif opts.key?(:service_plans)
        @service_plans = opts[:service_plans]
      end

      raise ActiveRecord::RecordNotFound, "Service Plan not found" if @service_plans.empty?

      @opts = opts
      @json = []
    end

    def process
      relevant_service_plans.each do |plan|
        @reference = plan.portfolio_item.service_offering_ref
        @portfolio_item_id = plan.portfolio_item.id
        @imported = true
        @modified = plan.modified.present?

        @service_plan = OpenStruct.new(
          :id                 => plan.id,
          :create_json_schema => relevant_schema(plan),
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

    def relevant_schema(plan)
      case @opts[:schema]
      when "base"
        plan.base
      when "modified"
        plan.modified
      else
        plan.send(:modified) || plan.send(:base)
      end
    end
  end
end
