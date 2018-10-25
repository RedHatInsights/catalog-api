require 'topological_inventory-api-client'

class TopologyServiceApi
  attr_accessor :params, :api_instance
  def initialize(options)
    @params = options
    TopologicalInventoryApiClient.configure do |config|
      config.host     = ENV['TOPOLOGY_SERVICE_URL']
      config.scheme   = URI.parse(ENV['TOPOLOGY_SERVICE_URL']).try(:scheme)
    end
    @api_instance = TopologicalInventoryApiClient::DefaultApi.new
  end

  def to_normalized_params
    hashy = instance_variables.each_with_object({}) do |var, hash|
      next if [:@params, :@api_instance].include?(var)
      hash[var.to_s.delete("@")] = instance_variable_get(var)
    end
    hashy.compact
  end

  private

  def apply_instance_vars(obj)
    uniq_ivars(obj).each do |ivar|
      value = obj.instance_variable_get(ivar)
      instance_variable_set(ivar, value)
    end
    self
  end

  def uniq_ivars(object)
    self.instance_variables & object.instance_variables
  end
end
