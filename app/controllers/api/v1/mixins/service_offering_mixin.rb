module Api
  module V1
    module Mixins
      module ServiceOfferingMixin
        private

        def service_offering_check(order)
          service_offering_service = Catalog::ServiceOffering.new(order).process
          if service_offering_service.archived
            raise Catalog::ServiceOfferingArchived, "Service offering for order #{order.id} has been archived and can no longer be ordered"
          end
        end
      end
    end
  end
end
