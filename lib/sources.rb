class Sources
  def self.sources_api
    Thread.current[:sources_api_instance] ||= raw_api
  end

  def self.call
    pass_thru_headers
    yield sources_api
  rescue SourcesApiClient::ApiError => e
    Rails.logger.error("SourcesApiClient::ApiError #{e.message}")
    raise Catalog::SourcesError, e.message
  end

  private_class_method def self.raw_api
    SourcesApiClient.configure do |config|
      config.host = ENV['SOURCES_URL'] || 'localhost'
      config.scheme = URI.parse(ENV['SOURCES_URL']).try(:scheme) || 'http'
      dev_credentials(config)
    end
    SourcesApiClient::DefaultApi.new
  rescue
    Rails.logger.error("Failed to connect to #{ENV['SOURCES_URL']}")
    raise
  end

  private_class_method def self.pass_thru_headers
    headers = Insights::API::Common::Request.current_forwardable
    sources_api.api_client.default_headers.merge!(headers)
  end
end
