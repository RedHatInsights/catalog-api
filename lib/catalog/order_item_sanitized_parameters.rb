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
      order_item.service_parameters_raw || {}
    end

    def filtered_parameters
      params = service_parameters_raw.slice(*fields.collect { |field| field[:name] })
      params.collect { |key, value| [key, sanitize_value(key, value)] }.to_h
    end

    def service_plan_schema
      service_plan = order_item.portfolio_item.service_plans&.first
      service_plan&.modified || service_plan&.base || live_service_plan_schema
    end

    def live_service_plan_schema
      TopologicalInventory::Service.call do |api|
        api.show_service_plan(service_plan_ref.to_s).create_json_schema
      end
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
      @fields ||= service_plan_schema.with_indifferent_access.dig(:schema, :fields)
    end

    def service_plan_does_not_exist?
      service_plan_ref.nil?
    end

    def sanitize_value(key, value)
      field = fields.find { |f| f[:name] == key }
      return value unless field[:isSubstitution]

      str_val = substitute(value)
      if str_val.blank?
        Rails.logger.warn("Substitution result for expression #{value} is blank")
        order_item.update_message("warn", "Parameter #{key} results an empty value after substitution")
      end

      begin
        convert_type(str_val, field[:type])
      rescue
        Rails.logger.error("Failed to convert #{str_val} to #{field[:type]}. Substitution expression #{value}, worksplace #{workspace}")
        raise
      end
    end

    def substitute(template)
      template.gsub!(ORDER_ITEM_REGEX) { |order_item_name| encode_name(order_item_name) }

      template.instance_of?(String) ? Mustache.render(template, workspace) : template
    rescue
      Rails.logger.error("Failed to substitute #{template} with workspace #{workspace}")
      raise
    end

    def convert_type(str, dtype)
      case dtype
      when 'integer'
        Integer(str)
      when 'float', 'number'
        Float(str)
      when 'boolean'
        raise ArgumentError, "Cannot convert #{str} to boolean" unless str.downcase! == 'true' || str == 'false'

        str == 'true'
      else
        str
      end
    end

    def encode_name(name)
      name.each_byte.map { |byte| byte.to_s(16) }.join
    end

    def workspace
      @workspace ||= Catalog::WorkspaceBuilder.new(order_item.order).process.workspace
    end
  end
end
