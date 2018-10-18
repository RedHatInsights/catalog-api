require 'topological_inventory-api-client'
class TopologyServiceApi
  attr_accessor :params, :api_instance
  def initialize(options)
    @params = options
    TopologicalInventoryApiClient.configure do |config|
      # Configure HTTP basic authorization: UserSecurity
      config.username = 'YOUR USERNAME'
      config.password = 'YOUR PASSWORD'
      config.host     = ENV['TOPOLOGY_SERVICE_URL']
      config.scheme   = 'http'
    end
    @api_instance = TopologicalInventoryApiClient::DefaultApi.new
  end
end
