module Catalog
  class SubmitNextOrderItem
    include SourceMixin

    attr_reader :order

    def initialize(order_id)
      @order_id = order_id
    end

    def process
      @order = Order.find_by!(:id => @order_id)

      # For now simply submit next order_item after previous one is completed
      order_item = @order.order_items.find(&:can_order?)
      return self unless order_item

      submit_order_item(order_item)

      @order.update(:state => 'Ordered', :order_request_sent_at => Time.now.utc) unless @order.state == 'Ordered'

      @order.reload
      self
    rescue => e
      Rails.logger.error("Error Submitting Order #{@order_id}: #{e.message}")
      raise
    end

    private

    def validate_before_submit(item)
      raise ::Catalog::NotAuthorized unless valid_source?(item.portfolio_item.service_offering_source_ref)

      return unless Catalog::SurveyCompare.any_changed?(item.portfolio_item.service_plans)

      item.mark_failed("Order Item Failed: Base survey does not match Topology")
      raise Catalog::InvalidSurvey, "Base survey does not match Topology"
    end

    def submit_order_item(item)
      validate_before_submit(item)
      TopologicalInventory::Service.call do |api_instance|
        result = api_instance.order_service_offering(item.portfolio_item.service_offering_ref, parameters(item))
        item.mark_ordered("Ordered", :topology_task_ref => result.task_id)
        Rails.logger.info("OrderItem #{item.id} ordered with topology task ref #{result.task_id}")
      end
      Rails.logger.info("Order Item #{item.id} submitted for provisioning")
    end

    def parameters(item)
      TopologicalInventoryApiClient::OrderParametersServiceOffering.new.tap do |obj|
        obj.service_parameters = sanitized_parameters(item)
        obj.provider_control_parameters = item.provider_control_parameters
        obj.service_plan_id = item.service_plan_ref
      end
    end

    def sanitized_parameters(item)
      Catalog::OrderItemSanitizedParameters.new(
        :order_item         => item,
        :do_not_mask_values => true
      ).process.sanitized_parameters
    end
  end
end
