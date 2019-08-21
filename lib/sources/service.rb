module Sources
  class Service
    def self.call(klass)
      setup
      yield init(klass)
    rescue SourcesApiClient::ApiError => err
      Rails.logger.error("SourcesApiClient::ApiError #{err.message} ")
      raise Catalog::SourcesError, err.message
    end

    private_class_method def self.setup
      SourcesApiClient.configure do |config|
        config.host   = ENV['SOURCES_URL'] || 'localhost'
        config.scheme = URI.parse(ENV['SOURCES_URL']).try(:scheme) || 'http'
        dev_credentials(config)
      end
    end

    private_class_method def self.init(klass)
      headers = ManageIQ::API::Common::Request.current_forwardable
      Rails.logger.info("Sending Headers to Sources #{headers}")
      klass.new.tap do |api|
        api.api_client.default_headers = api.api_client.default_headers.merge(headers)
      end
    end
  end
end
