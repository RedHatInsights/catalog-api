class TopologicalInventory
  def self.api
    Thread.current[:api_instance] ||= raw_api
  end

  def self.call
    pass_thru_headers
    yield api
  rescue TopologicalInventoryApiClient::ApiError => err
    Rails.logger.error("TopologicalInventoryApiClient::ApiError #{err.message} ")
    raise ServiceCatalog::TopologyError, err.message
  end

  private_class_method def self.raw_api
    TopologicalInventoryApiClient.configure do |config|
      config.host   = 'localhost'
      config.scheme = 'http'
    end
  end

  private_class_method def self.pass_thru_headers
    {}
  end
end
