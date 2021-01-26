module Api
  module V1x2
    module Catalog
      class TaggingService
        TAG_NAMESPACE = 'catalog'.freeze
        TAG_NAME = 'order_processes'.freeze
        QUERY_LIMIT = 1000

        REMOTE_SERVICES = {
          "sources"           => {
            :service_class => ::Sources,
            :api_class     => ::SourcesApiClient::DefaultApi,
            :tag_class     => nil # nil -> ::SourcesApiClient::Tag when it is available
          },
          "catalog-inventory" => {
            :service_class => ::CatalogInventory::Service,
            :api_class     => ::CatalogInventoryApiClient::ServiceInventoryApi,
            :tag_class     => ::CatalogInventoryApiClient::Tag
          }
        }.freeze

        CATALOG_OBJECT_TYPES = [Portfolio.name, PortfolioItem.name].freeze

        def initialize(params)
          @app_name = params.require(:app_name)
          raise ::Catalog::InvalidParameter, "#{@app_name} is not supported for tagging service" unless suppported_service?(@app_name)

          @object_type = params.require(:object_type)
          @object_id = params.require(:object_id)
          @params = params.slice(:object_type, :object_id, :app_name).to_unsafe_h
        end

        private

        def suppported_service?(service)
          ["catalog", REMOTE_SERVICES.keys].flatten.include?(service)
        end

        def catalog_object_type?
          @app_name == "catalog" && CATALOG_OBJECT_TYPES.include?(@object_type)
        end

        def call_tagging_service
          catalog_object_type? ? call_local_service : call_remote_service(tags)
        end

        def call_local_service
          object.send(api_method_name, TAG_NAME, :namespace => TAG_NAMESPACE, :value => @order_process.id)
        end

        def object
          @object_type.classify.constantize.find(@object_id)
        end

        def call_remote_service(options = {:limit => QUERY_LIMIT})
          # TODO: better way for generic remote service
          # catalog-inventory service's call need class info
          service_class = REMOTE_SERVICES[@app_name][:service_class]
          api_class     = REMOTE_SERVICES[@app_name][:api_class]

          service_class.call(api_class) do |api|
            api.send(api_method_name, @object_id, options)
          end
        end

        def tags
          api_tag_klass = REMOTE_SERVICES[@app_name][:tag_class]

          [api_tag_klass.new(:tag => tag_content)]
        end

        # {:app_name => 'catalog', :object_type => 'Portfolio", :order_process_id => 123, :tag_name => '/catalog/order_processes=123'}
        def tag_link
          @params.except(:object_id).merge(:order_process_id => @order_process.id, :tag_name => tag_content)
        end

        # "/catalog/order_processes=123"
        def tag_content
          "/#{TAG_NAMESPACE}/#{TAG_NAME}=#{@order_process.id}"
        end
      end
    end
  end
end
