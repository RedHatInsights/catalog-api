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
        item.resource_definitions.collect do |rd|
          rd.attribute_filter.value
        end
      end.flatten
    end

    def self.enabled?
      enabled = ENV['BYPASS_RBAC'].blank?

      # Temporary hack to allow per-tenant enabling of RBAC while we test
      # TODO: Delete as soon as possible
      if enabled == true
        return enabled if ENV['RAILS_ENV'] == 'test'
        enabled = false if ActsAsTenant.current_tenant.try(:rbac_enabled?) == false
      end

      enabled
    end
  end
end
