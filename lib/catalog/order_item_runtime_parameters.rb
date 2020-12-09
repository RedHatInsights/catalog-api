module Catalog
  class OrderItemRuntimeParameters
    attr_reader :runtime_parameters

    ORDER_ITEM_REGEX = /(?<=\{\{after\.|before\.)(.+?)(?=\.artifacts|\.extra_vars|\.status.*\}\})/.freeze

    def initialize(order_item)
      @order_item = order_item
    end

    def process
      @runtime_parameters = compute_runtime_parameters
      self
    rescue => e
      Rails.logger.error("OrderItemRuntimeParameters #{e.message}")
      raise
    end

    private

    def compute_runtime_parameters
      return {} unless @order_item.service_plan_ref

      params = service_parameters_raw.slice(*fields.collect { |field| field[:name] })
      params.collect { |key, value| [key, compute_value(key, value)] }.to_h
    end

    def fields
      @fields ||= ServicePlanFields.new(@order_item).process.fields
    end

    def service_parameters_raw
      @order_item.service_parameters_raw || {}
    end

    def compute_value(key, value)
      field = fields.find { |f| f[:name] == key }
      return value unless field[:isSubstitution]

      str_val = substitute(value)
      if str_val.blank?
        Rails.logger.warn("Substitution result for expression #{value} is blank")
        @order_item.update_message("warn", "Parameter #{key} results an empty value after substitution")
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
      @workspace ||= Catalog::WorkspaceBuilder.new(@order_item.order).process.workspace
    end
  end
end
