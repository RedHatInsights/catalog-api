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
        Rails.logger.info("Fetch access list for #{@app_name}")
        @acl = RBAC::Service.paginate(api, :get_principal_access, {}, @app_name).select do |item|
          Rails.logger.info("Found ACL: #{item}")
          @regexp.match(item.permission)
        end
      end
      self
    end

    def accessible?
      Rails.logger.info("ACL for #{@app_name} #{@acl}")
      @acl.any?
    end

    def id_list
      ids = collect_ids
      Rails.logger.info("IDS for #{@app_name} #{ids}")
      ids.include?('*') ? [] : ids
    end

    def self.enabled?
      ENV['BYPASS_RBAC'].blank?
    end

    private
    def collect_ids
      @acl.collect do |item|
        item.resource_definitions.collect do |rd|
          rd.attribute_filter.value
        end
      end.flatten
    end
  end
end
