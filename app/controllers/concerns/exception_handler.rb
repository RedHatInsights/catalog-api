module ExceptionHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound do |err|
      Rails.logger.error("Not found: #{err.message}")
      json_response({:message => "Not Found"}, :not_found)
    end

    rescue_from Catalog::TopologyError do |err|
      json_response({:message => err.message}, :internal_server_error)
    end

    rescue_from Catalog::NotAuthorized,                  :with => :forbidden_error
    rescue_from ManageIQ::API::Common::EntitlementError, :with => :forbidden_error

    rescue_from ManageIQ::API::Common::IdentityError do |err|
      Rails.logger.error("Unauthorized error: #{err.message}")
      json_response({:message => "Unauthorized"}, :unauthorized)
    end

    rescue_from Discard::DiscardError do |err|
      json_response({:message => err.message}, :unprocessable_entity)
    end
  end

  private

  def forbidden_error(err)
    Rails.logger.error("Forbidden error: #{err.message}")
    json_response({:message => "Forbidden"}, :forbidden)
  end
end
