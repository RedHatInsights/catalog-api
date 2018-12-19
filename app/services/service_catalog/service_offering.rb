module ServiceCatalog
  class ServiceOffering
    def initialize
      @name = nil
      @description = nil
      @service_offering_ref = nil
    end

    def self.find(id)
      new.show(id)
    end

    def show(id)
      @service_offering_ref = id
      TopologicalInventory.call do |api_instance|
        obj = api_instance.show_service_offering(id)
        apply_instance_vars(obj)
      end
    end

    def to_normalized_params
      hashy = instance_variables.each_with_object({}) do |var, hash|
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
      instance_variables & object.instance_variables
    end
  end
end
