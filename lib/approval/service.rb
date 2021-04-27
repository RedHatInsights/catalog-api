module Approval
  class Service
    def self.call(klass)
      setup
      yield init(klass)
    rescue ApprovalApiClient::ApiError => e
      Rails.logger.error("ApprovalApiClient::ApiError #{e.message}")
      raise Catalog::ApprovalError, e.message
    end

    private_class_method def self.setup
      ApprovalApiClient.configure do |config|
        config.host = ENV['APPROVAL_URL'] || 'localhost'
        config.scheme = URI.parse(ENV['APPROVAL_URL']).try(:scheme) || 'http'
        dev_credentials(config)
      end
    rescue
      Rails.logger.error("Failed to connect to #{ENV['APPROVAL_URL']}")
      raise
    end

    private_class_method def self.init(klass)
      headers = Insights::API::Common::Request.current_forwardable
      klass.new.tap do |api|
        api.api_client.default_headers.merge!(headers)
      end
    end
  end
end
