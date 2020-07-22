module Api
  module V1x2
    module Catalog
      class UnlinkFromOrderProcess < TaggingService
        attr_reader :order_process

        def initialize(params)
          super
          @order_process = OrderProcess.find(params.require(:id))
        end

        def process
          TagLink.where(tag_link).delete_all
          call_tagging_service(self.class)

          self
        end
      end
    end
  end
end
