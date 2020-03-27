module Api
  module V1x0
    module Mixins
      module ServiceOfferingMixin
        private

        def service_offering_check
          service_offering_service = Api::V1x0::Catalog::ServiceOffering.new(@order).process
          if service_offering_service.archived
            @order.order_items.each do |order_item|
              order_item.mark_failed(archived_error_message)
            end

            raise Catalog::ServiceOfferingArchived, archived_error_message
          end
        end

        def archived_error_message
          "Order Failed: Service offering for order #{@order.id} has been archived and can no longer be ordered"
        end
      end
    end
  end
end
