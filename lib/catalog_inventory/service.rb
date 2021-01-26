require 'catalog_inventory-api-client-ruby'

module CatalogInventory
  class Service
    def self.call(klass)
      setup
      yield init(klass)
    rescue CatalogInventoryApiClient::ApiError => err
      Rails.logger.error("CatalogInventoryApiClient::ApiError #{err.message} ")
      raise Catalog::InventoryError, err.message
    end

    private_class_method def self.setup
      CatalogInventoryApiClient.configure do |config|
        config.host = ENV['CATALOG_INVENTORY_URL'] || 'localhost'
        config.scheme = URI.parse(ENV['CATALOG_INVENTORY_URL']).try(:scheme) || 'http'
        dev_credentials(config)
      end
    end

    private_class_method def self.init(klass)
      headers = Insights::API::Common::Request.current_forwardable
      klass.new.tap do |api|
        api.api_client.default_headers.merge!(headers)
      end
    end
  end
end
