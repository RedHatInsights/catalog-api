require 'mustache'

module Catalog
  class OrderItemSanitizedParameters
    attr_reader :sanitized_parameters

    MASKED_VALUE = "$protected$".freeze
    FILTERED_PARAMS = %w[password token secret].freeze
    ORDER_ITEM_REGEX = /(?<=\{\{after\.|applicable\.|before\.)(.+?)(?=\.artifacts|\.extra_vars|\.status.*\}\})/.freeze

    def initialize(params)
      @params = params
      @order_item = params[:order_item]
    end

    def process
      @sanitized_parameters = compute_sanitized_parameters

      self
    rescue => e
      Rails.logger.error("OrderItemSanitizedParameters #{e.message}")
      raise
    end

    private

    def order_item
      @order_item ||= OrderItem.find(@params[:order_item_id])
    end

    def service_plan_ref
      order_item.service_plan_ref
    end

    def service_parameters_raw
      order_item.service_parameters_raw
    end

    def filtered_parameters
      params = service_parameters_raw.slice(*fields.collect { |field| field.with_indifferent_access["name"] })
      params.transform_values! { |v| substitute(v) }
    end

    def service_plan_schema
      TopologicalInventory::Service.call do |api|
        @plan = api.show_service_plan(service_plan_ref.to_s)
      end
      @plan.create_json_schema
    rescue ::Catalog::TopologyError => e
      Rails.logger.error("DefaultApi->show_service_plan #{e.message}")
      raise
    end

    def compute_sanitized_parameters
      return {} if service_plan_does_not_exist?
      return filtered_parameters if @params[:do_not_mask_values]

      svc_params = ActiveSupport::HashWithIndifferentAccess.new(service_parameters_raw)
      fields.each_with_object({}) do |field, result|
        value = mask_value?(field) ? MASKED_VALUE : svc_params[field[:name]]
        result[field[:name]] = value
      end
    end

    def mask_value?(field)
      FILTERED_PARAMS.reduce(field[:type] == "password") do |result, param|
        result || /#{param}/i.match?(field[:name]) || /#{param}/i.match?(field[:label])
      end
    end

    def fields
      service_plan_schema.dig(:schema, :fields) || []
    end

    def service_plan_does_not_exist?
      service_plan_ref.nil?
    end

    def substitute(template)
      template.gsub!(ORDER_ITEM_REGEX) { |order_item_name| encode_name(order_item_name) }

      template.instance_of?(String) ? Mustache.render(template, workspace) : template
    rescue
      Rails.logger.error("Failed to substitue #{template} with workspace #{workspace}")
      raise
    end

    def encode_name(name)
      name.each_byte.map { |byte| byte.to_s(16) }.join
    end

    def workspace
      @workspace ||= Catalog::WorkspaceBuilder.new(order_item.order).process.workspace
    end
  end
end
