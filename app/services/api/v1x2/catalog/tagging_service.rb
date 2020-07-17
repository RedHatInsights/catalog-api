require 'faraday'

module Api
  module V1x2
    module Catalog
      class TaggingService
        TAG_NAMESPACE = 'catalog'.freeze
        TAG_NAME = 'order_processes'.freeze
        QUERY_LIMIT = 1000
        CATALOG_OBJECT_TYPES = [Portfolio.name, PortfolioItem.name].freeze

        def initialize(params)
          @app_name = params.require(:app_name)
          @object_type = params.require(:object_type)
          @object_id = params.require(:object_id)
          @params = params.slice(:object_type, :object_id, :app_name).to_unsafe_h
        end

        def self.remotes
          [{:app_name => 'topology', :object_type => 'ServiceInventory', :url => proc { topo_url }},
           {:app_name => 'topology', :object_type => 'Credential',       :url => proc { topo_url }},
           {:app_name => 'sources',  :object_type => 'Source',           :url => proc { sources_url }}]
        end

        def catalog_object_type?
          CATALOG_OBJECT_TYPES.include?(@object_type)
        end

        private

        def self.topo_url
          url = ENV.fetch('TOPOLOGICAL_INVENTORY_URL') { raise 'TOPOLOGICAL_INVENTORY_URL is not set' }
          "#{url}/api/topological-inventory/v2.0"
        end
        private_class_method :topo_url

        def self.sources_url
          url = ENV.fetch('SOURCES_URL') { raise 'SOURCES_URL is not set' }
          "#{url}/api/sources/v1.0"
        end
        private_class_method :sources_url

        # {:app_name => 'catalog', :object_type => 'Portfolio", :order_process_id => 123, :tag_name => '/catalog/order_processes=123'}
        def tag_link
          @params.except(:object_id).merge(:order_process_id => @order_process.id, :tag_name => tag_content)
        end

        # "/catalog/order_processes=123"
        def tag_content
          "/#{TAG_NAMESPACE}/#{TAG_NAME}=#{@order_process.id}"
        end

        def object
          object_klass.find(@object_id)
        end

        def object_klass
          @params[:object_type].classify.safe_constantize
        end

        def object_url
          "#{service_url}/#{@object_type.underscore.pluralize}/#{@object_id}/tags"
        end

        def service_url
          match = self.class.remotes.detect { |item| item[:app_name] == @app_name && item[:object_type] == @object_type }
          raise ::Catalog::InvalidParameter, "No url found for app #{@app_name} object #{@object_type}" unless match

          match[:url].call
        end

        def post_request(url, tags)
          call_remote_service do |con|
            con.post(url) do |session|
              session.headers['Content-Type'] = 'application/json'
              headers(session)
              session.body = tags.to_json
            end
          end
        end

        def get_request(url, params)
          call_remote_service do |con|
            con.get(url) do |session|
              headers(session)
              params.each { |k, v| session.params[k] = v }
            end
          end
        end

        def call_remote_service
          connection = Faraday.new
          yield(connection)
        rescue Faraday::TimeoutError => e
          raise ::Catalog::TimedOutError, e.message
        rescue Faraday::ConnectionFailed => e
          raise ::Catalog::NetworkError, e.message
        rescue Faraday::UnauthorizedError => e
          raise ::Catalog::NotAuthorized, e.message
        rescue Faraday::Error => e
          raise ::Catalog::InvalidTag, e.message
        end

        def headers(session)
          Insights::API::Common::Request.current_forwardable.each do |k, v|
            session.headers[k] = v
          end
        end
      end
    end
  end
end
