module Api
  module V1x2
    module Catalog
      class LinkToOrderProcess < TaggingService
        attr_reader :order_process

        def initialize(params)
          super
          @order_process = OrderProcess.find(params.require(:id))
        end

        def process
          TagLink.find_or_create_by!(tag_link)
          catalog_object_type? ? catalog_post_request : post_request(object_url, @params)

          self
        end

        private

        def object_url
          "#{service_url}/#{@object_type.underscore.pluralize}/#{@object_id}/tag"
        end

        def catalog_post_request
          object.tag_add(TAG_NAME, :namespace => TAG_NAMESPACE, :value => @order_process.id)
        end
      end
    end
  end
end
