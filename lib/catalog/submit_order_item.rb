module Catalog
  class SubmitOrderItem
    include SourceMixin

    attr_reader :order_item

    def initialize(order_item)
      @order_item = order_item
    end

    def process
      @order_item.update_message("info", "Submitting Order Item for provisioning")
      validate_before_submit

      TopologicalInventory::Service.call do |api_instance|
        result = api_instance.order_service_offering(order_item.portfolio_item.service_offering_ref, service_offering)
        order_item.mark_ordered(:topology_task_ref => result.task_id)
        Rails.logger.info("OrderItem #{order_item.id} ordered with topology task ref #{result.task_id}")
      end
      self
    rescue => e
      @order_item.mark_failed("Error Submitting Order Item: #{e.message}")
    ensure
      order_item.update(:service_parameters => runtime_parameters)
    end

    private

    def validate_before_submit
      raise ::Catalog::NotAuthorized unless valid_source?(order_item.portfolio_item.service_offering_source_ref)

      validate_surveys
    end

    def service_offering
      TopologicalInventoryApiClient::OrderParametersServiceOffering.new.tap do |obj|
        obj.service_parameters = runtime_parameters
        obj.provider_control_parameters = order_item.provider_control_parameters
        obj.service_plan_id = order_item.service_plan_ref
      end
    end

    def validate_surveys
      changed_surveys = ::Catalog::SurveyCompare.collect_changed(order_item.portfolio_item.service_plans)

      unless changed_surveys.empty?
        invalid_survey_messages = changed_surveys.collect(&:invalid_survey_message)
        raise ::Catalog::InvalidSurvey, invalid_survey_messages.join('; ')
      end
    end

    def runtime_parameters
      @runtime_parameters ||= OrderItemRuntimeParameters.new(order_item).process.runtime_parameters
    end
  end
end
