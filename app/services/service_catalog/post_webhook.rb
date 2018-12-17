require 'base64'
require 'rest-client'
module ServiceCatalog
  class PostWebhook
    USER_AGENT = 'Redhat Insights Portal v1.0.0'.freeze
    SIGNATURE_KEY = 'X-Service-Portal-Signature'.freeze

    def initialize(options)
      @options = options
      validate
      @headers = default_headers
      add_authorization_headers
    end

    def process(json)
      add_hmac_headers(json)
      post(json)
    end

    private

    def validate
      raise ArgumentError, "url not specified" if @options['url'].blank?
      validate_auth
    end

    def validate_auth
      case @options['authentication']
      when 'oauth'
        raise ArgumentError, 'bearer token not specified' if @options['token'].blank?
      when 'basic'
        raise ArgumentError, 'username not specified' if @options['username'].blank?
        raise ArgumentError, "password not specified" if @options['password'].blank?
      end
    end

    def default_headers
      {
        'User-Agent'   => USER_AGENT,
        'Content-Type' => "application/json",
        'Accept'       => "application/json"
      }
    end

    def add_authorization_headers
      case @options['authentication']
      when 'basic'
        @headers['Authorization'] = "Basic " + Base64.encode64("#{@options['username']}:#{@options['password']}")
      when 'oauth'
        @headers['Authorization'] = "Bearer #{@options['token']}"
      end
    end

    def add_hmac_headers(json)
      @headers[SIGNATURE_KEY] = signature(json) if @options['secret']
    end

    def signature(json)
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), @options['secret'], json)
    end

    def post(json)
      response = RestClient::Request.new(:method     => :post,
                                         :url        => @options['url'],
                                         :headers    => @headers,
                                         :verify_ssl => @options.fetch('verify_ssl', true),
                                         :payload    => json).execute
      response.code
    rescue StandardError => err
      raise err.message
    end
  end
end
