require 'topological_inventory-api-client'

class TopologyApiService
  attr_accessor :params, :api_instance
  def initialize(options)
    @params = options
    TopologicalInventoryApiClient.configure do |config|
      config.host     = ENV['TOPOLOGY_SERVICE_URL']
      config.scheme   = URI.parse(ENV['TOPOLOGY_SERVICE_URL']).try(:scheme)
    end
    @api_instance = TopologicalInventoryApiClient::DefaultApi.new
  end
end
