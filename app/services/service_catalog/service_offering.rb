class ServiceOffering < TopologyServiceApi

  def initialize(params)
    @name = nil
    @description = nil
    @service_offering_ref = nil
    super(params)
  end

  def self.find(id)
    new({}).show(id)
  end

  def show(id)
    @service_offering_ref = id
    obj = api_instance.show_service_offering(id)
    apply_instance_vars(obj)
  rescue TopologicalInventoryApiClient::ApiError => e
    Rails.logger.error("TopologicalInventoryApiClient::ApiError #{e.message}")
    raise ActiveRecord::RecordNotFound
  end
end
