module Catalog
  class SubmitOrder
    include SourceMixin
    include SurveyMixin

    attr_reader :order

    def initialize(order_id)
      @order_id = order_id
    end

    def process
      @order = Order.find_by!(:id => @order_id)
      @order.order_items.each do |order_item|
        raise Catalog::NotAuthorized unless valid_source?(order_item.portfolio_item.service_offering_source_ref)
        raise Catalog::InvalidSurvey, "Base survey does not match Topology" if item_surveys_changed?(order_item.portfolio_item)

        submit_order_item(order_item)
      end
      @order.update(:state => 'Ordered', :order_request_sent_at => Time.now.utc)
      @order.reload
      self
    rescue StandardError => e
      Rails.logger.error("Submit Order #{e.message}")
      raise
    end

    private

    def submit_order_item(item)
      TopologicalInventory.call do |api_instance|
        result = api_instance.order_service_offering(item.portfolio_item.service_offering_ref, parameters(item))
        update_item(item, result)
      end
    end

    def parameters(item)
      TopologicalInventoryApiClient::OrderParametersServiceOffering.new.tap do |obj|
        obj.service_parameters = sanitized_parameters(item)
        obj.provider_control_parameters = item.provider_control_parameters
        obj.service_plan_id = item.service_plan_ref
      end
    end

    def update_item(item, result)
      item.topology_task_ref     = result.task_id
      item.state                 = 'Ordered'
      item.order_request_sent_at = Time.now.utc
      item.update_message('info', 'Ordered')
      item.save!
    end

    def sanitized_parameters(item)
      Catalog::OrderItemSanitizedParameters.new(
        :order_item         => item,
        :do_not_mask_values => true
      ).process.sanitized_parameters
    end
  end
end
