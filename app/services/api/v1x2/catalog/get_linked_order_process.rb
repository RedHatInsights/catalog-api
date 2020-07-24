module Api
  module V1x2
    module Catalog
      class GetLinkedOrderProcess < TaggingService
        attr_reader :order_processes

        def process
          order_process_ids = TagLink.where(@params.except(:object_id)).where(:tag_name => link_tags).pluck(:order_process_id)
          @order_processes = OrderProcess.where(:id => order_process_ids)

          self
        end

        private

        def link_tags
          if catalog_object_type?
            object.tags.collect(&:to_tag_string)
          else
            response = call_remote_service
            response.data.collect(&:tag)
          end
        end

        def api_method_name
          catalog_object_type? ? "tags" : "list_#{@object_type.underscore}_tags"
        end
      end
    end
  end
end
