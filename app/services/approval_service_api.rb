require 'approval_api_client'

class ApprovalServiceApi
  attr_reader :params
  attr_reader :api_instance
  attr_reader :request

  def initialize(options)
    @params = options[:params]
    @request = options[:request]
    ApprovalAPIClient.configure do |config|
      config.host     = ENV['APPROVAL_SERVICE_URL']
      config.scheme   = URI.parse(ENV['APPROVAL_SERVICE_URL']).try(:scheme)
    end
    @api_instance = ApprovalAPIClient::UsersApi.new
    set_identity_header
  end

  def set_identity_header
    x_rh = {
      'x-rh-auth-identity' => request.headers['x-rh-auth-identity']
    }
    api_instance.api_client.default_headers.merge!(x_rh)
  end
end
