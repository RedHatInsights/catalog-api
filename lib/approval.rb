require 'approval_api_client'

class Approval
  def self.approval_api
    Thread.current[:approval_api_instance] ||= raw_api
  end

  def self.call
    pass_thru_headers
    yield approval_api
  rescue ApprovalAPIClient::APIError => e
    Rails.logger.error("ApprovalApiClient::ApiError #{e.message}")
    raise Catalog::ApprovalError, e.message
  end

  private_class_method def self.raw_api
    ApprovalApiClient.configure do |config|
      config.host = ENV['APPROVAL_URL'] || 'localhost'
      config.scheme = URI.parse(ENV['APPROVAL_URL']).try(:scheme) || 'http'
      dev_credentials(config)
    end
    ApprovalApiClient::RequestApi.new
  end

  private_class_method def self.pass_thru_headers
    headers = ManageIQ::API::Common::Request.current_forwardable
    approval_api.api_client.default_headers = api.api_client.default_headers.merge(headers)
  end
end
