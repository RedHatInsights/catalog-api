require 'topological_inventory-api-client'
class TopologicalInventory
  DEFAULT_PATH_PREFIX = 'api'.freeze
  SERVICE_NAME = 'topological-inventory'.freeze
  VERSION = 'v1.0'.freeze

  def self.api
    Thread.current[:api_instance] ||= raw_api
  end

  def self.call
    pass_thru_headers
    yield api
  rescue TopologicalInventoryApiClient::ApiError => err
    Rails.logger.error("TopologicalInventoryApiClient::ApiError #{err.message} ")
    raise Catalog::TopologyError, err.message
  end

  private_class_method def self.raw_api
    TopologicalInventoryApiClient.configure do |config|
      config.host = ENV['TOPOLOGICAL_INVENTORY_URL'] || 'localhost'
      config.scheme = URI.parse(ENV['TOPOLOGICAL_INVENTORY_URL']).try(:scheme) || 'http'
      config.base_path = File.join("/", ENV['PATH_PREFIX'].presence || DEFAULT_PATH_PREFIX, SERVICE_NAME, VERSION)
      dev_credentials(config)
    end
    TopologicalInventoryApiClient::DefaultApi.new
  end

  private_class_method def self.pass_thru_headers
    headers = ManageIQ::API::Common::Request.current_forwardable
    api.api_client.default_headers = api.api_client.default_headers.merge(headers)
  end
end
