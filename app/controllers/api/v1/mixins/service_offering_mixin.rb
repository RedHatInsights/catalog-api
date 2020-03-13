module Api
  module V1
    module Mixins
      module ServiceOfferingMixin
        private

        def service_offering_check
          service_offering_service = Catalog::ServiceOffering.new(@order).process
          if service_offering_service.archived
            @order.order_items.each do |order_item|
              order_item.update!(:completed_at => DateTime.now, :state => "Failed")
              order_item.update_message("error", archived_error_message)
            end

            @order.update!(:state => "Failed")

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
