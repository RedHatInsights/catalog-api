require 'approval-api-client-ruby'

class Approval
  def self.approval_api
    Thread.current[:approval_api_instance] ||= raw_api
  end

  def self.action_api
    Thread.current[:approval_action_api_instance] ||= raw_action_api
  end

  def self.call
    pass_thru_headers
    yield approval_api
  rescue ApprovalApiClient::ApiError => e
    Rails.logger.error("ApprovalApiClient::ApiError #{e.message}")
    raise Catalog::ApprovalError, e.message
  end

  def self.call_action_api
    pass_thru_headers
    yield action_api
  rescue ApprovalApiClient::ApiError => e
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

  private_class_method def self.raw_action_api
    ApprovalApiClient.configure do |config|
      config.host = ENV['APPROVAL_URL'] || 'localhost'
      config.scheme = URI.parse(ENV['APPROVAL_URL']).try(:scheme) || 'http'
      dev_credentials(config)
    end
    ApprovalApiClient::ActionApi.new
  end

  private_class_method def self.pass_thru_headers
    headers = ManageIQ::API::Common::Request.current_forwardable
    approval_api.api_client.default_headers.merge!(headers)
  end
end
