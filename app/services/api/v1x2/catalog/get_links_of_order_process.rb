module Api
  module V1x2
    module Catalog
      class GetLinksOfOrderProcess < TaggingService
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
            params = {}
            params['limit'] = QUERY_LIMIT
            response = get_request(object_url, params)

            JSON.parse(response.body)['data'].collect { |tag| tag['tag'] }
          end
        end
      end
    end
  end
end
