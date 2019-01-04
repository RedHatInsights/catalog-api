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
      obj = nil
      TopologicalInventory.call do |api_instance|
        obj = JSON.parse(File.read("#{Rails.root}/spec/support/service_catalog/service_offering.json"))
      end
      resp = obj.select { |x| x['id'] == id }
      @normalized = resp.first
      self
    end

    def to_normalized_params
      hashy = instance_variables.each_with_object({}) do |var, hash|
        next if var == :@normalized
        hash[var.to_s.delete("@")] = instance_variable_get(var)
      end
      if @normalized
        @normalized["service_offering_ref"] = @normalized["id"]
        @normalized
      else
        hashy.compact
      end
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
