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
          call_tagging_service

          self
        end

        private

        def api_method_name
          catalog_object_type? ? "tag_remove" : "untag_#{@object_type.underscore}"
        end
      end
    end
  end
end
