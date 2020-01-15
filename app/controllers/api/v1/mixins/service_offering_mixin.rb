module Api
  module V1
    module Mixins
      module ServiceOfferingMixin
        private

        def service_offering_check
          order_id = params.require(:order_id)
          service_offering_service = Catalog::ServiceOffering.new(order_id).process
          if service_offering_service.archived
            raise Catalog::ServiceOfferingArchived, "Service offering for order #{order_id} has been archived and can no longer be ordered"
          else
            @order = service_offering_service.order
          end
        end
      end
    end
  end
end
