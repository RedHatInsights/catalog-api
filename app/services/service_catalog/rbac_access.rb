module ServiceCatalog
  class RBACAccess
    attr_reader :acl
    def initialize(resource, verb)
      @resource = resource
      @verb     = verb
      @regexp   = Regexp.new(":(#{@resource}|\\*):(#{@verb}|\\*)")
    end

    def process
      RBACService.call(RBACApiClient::AccessApi) do |api|
        @acl = RBACService.paginate(api, :get_principal_access,  {}, 'catalog').select do |item|
          @regexp.match(item.permission)
        end
      end
      self
    end

    def accessible?
      @acl.any?
    end

    def id_list
      @acl.collect do |item|
        item.resource_definition.collect do |rd|
          rd.attribute_filter.value
        end
      end.flatten
    end
  end
end
