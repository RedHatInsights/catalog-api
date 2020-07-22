module Api
  module V1x2
    module Catalog
      class TaggingService
        TAG_NAMESPACE = 'catalog'.freeze
        TAG_NAME = 'order_processes'.freeze
        QUERY_LIMIT = 1000

        REMOTE_SERVICES = {"sources"  => ::Sources,
                           "topology" => ::TopologicalInventory}.freeze

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

        def call_tagging_service(klass)
          catalog_object_type? ? call_local_service(klass) : call_remote_service(klass, tags)
        end

        def call_local_service(klass)
          method = api_method_name(klass, false)
          object.send(method, TAG_NAME, :namespace => TAG_NAMESPACE, :value => @order_process.id)
        end

        def object
          @object_type.classify.constantize.find(@object_id)
        end

        def call_remote_service(klass, options = {:limit => QUERY_LIMIT})
          REMOTE_SERVICES[@app_name].call do |api|
            method = api_method_name(klass)
            api.send(method, @object_id, options)
          end
        end

        def api_method_name(klass, remote = true)
          case klass.name
          when "Api::V1x2::Catalog::GetLinkedOrderProcess"
            remote ? "list_#{@object_type.underscore}_tags" : "tags"
          when "Api::V1x2::Catalog::LinkToOrderProcess"
            remote ? "tag_#{@object_type.underscore}" : "tag_add"
          when "Api::V1x2::Catalog::UnlinkFromOrderProcess"
            remote ? "untag_#{@object_type.underscore}" : "tag_remove"
          else
            raise ::Catalog::InvalidParameter, "No #{klass} found for tagging service"
          end
        end

        def tags
          api_tag_klass = "#{REMOTE_SERVICES[@app_name].name}ApiClient::Tag".classify.constantize

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
