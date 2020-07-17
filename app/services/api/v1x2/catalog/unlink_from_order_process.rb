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
          catalog_object_type? ? catalog_post_request : post_request(object_url, @params)

          self
        end

        private

        def object_url
          "#{service_url}/#{@object_type.underscore.pluralize}/#{@object_id}/untag"
        end

        def catalog_post_request
          object.tag_remove(TAG_NAME,
                            :namespace => TAG_NAMESPACE,
                            :value     => @order_process.id.to_s)
        end
      end
    end
  end
end
