module ExceptionHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound do |err|
      Rails.logger.error("Not found: #{err.message}")
      json_response({:message => "Not Found"}, :not_found)
    end
  end
end
