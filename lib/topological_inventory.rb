require 'topological_inventory-api-client'
class TopologicalInventory
  def self.api
    TopologicalInventoryApiClient.configure do |config|
      config.host     = ENV['TOPOLOGICAL_INVENTORY_URL']
      config.scheme   = URI.parse(ENV['TOPOLOGICAL_INVENTORY_URL']).try(:scheme)
    end
    TopologicalInventoryApiClient::DefaultApi.new
  end
end
