module RBAC
  class Access
    attr_reader :acl
    def initialize(resource, verb)
      @resource = resource
      @verb     = verb
      @regexp   = Regexp.new(":(#{@resource}|\\*):(#{@verb}|\\*)")
      @app_name = ENV["APP_NAME"] || "catalog"
    end

    def process
      RBAC::Service.call(RBACApiClient::AccessApi) do |api|
        @acl = RBAC::Service.paginate(api, :get_principal_access, {}, @app_name).select do |item|
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

    def self.enabled?
      ENV['BYPASS_RBAC'].blank?
    end
  end
end
