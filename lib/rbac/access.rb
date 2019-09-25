module RBAC
  class Access
    attr_reader :acl
    DEFAULT_LIMIT = 500
    def initialize(resource, verb)
      @resource = resource
      @verb     = verb
      @regexp   = Regexp.new(":(#{@resource}|\\*):(#{@verb}|\\*)")
      @app_name = ENV["APP_NAME"]
    end

    def process
      RBAC::Service.call(RBACApiClient::AccessApi) do |api|
        Rails.logger.info("Fetch access list for #{@app_name}")
        @acl = RBAC::Service.paginate(api, :get_principal_access, {:limit => DEFAULT_LIMIT}, @app_name).select do |item|
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
      generate_ids
      Rails.logger.info("IDS for #{@app_name} #{@ids}")
      @ids.include?('*') ? [] : @ids
    end

    def owner_scoped?
      generate_ids
      @ids.include?('*') ? false : owner_scope_filter?
    end

    def self.enabled?
      ENV['BYPASS_RBAC'].blank?
    end

    private

    def generate_ids
      @ids ||= @acl.each_with_object([]) do |item, ids|
        item.resource_definitions.each do |rd|
          next unless rd.attribute_filter.key == 'id'
          next unless rd.attribute_filter.operation == 'equal'

          ids << rd.attribute_filter.value
        end
      end
    end

    def owner_scope_filter?
      @acl.any? do |item|
        item.resource_definitions.any? do |rd|
          rd.attribute_filter.key == 'owner' &&
            rd.attribute_filter.operation == 'equal' &&
            rd.attribute_filter.value == '{{username}}'
        end
      end
    end
  end
end
