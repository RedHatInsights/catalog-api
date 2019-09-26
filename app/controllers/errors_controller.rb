class ErrorsController < ApplicationController
  self.openapi_enabled = false
  skip_before_action :validate_primary_collection_id

  def not_found
    @exception = request.env["action_dispatch.exception"]
    Rails.logger.error(@exception.message)

    json_response({:message => "Not Found"}, request.path[1..-1])
  end

  def catch_all
    @exception = request.env["action_dispatch.exception"]
    Rails.logger.error(@exception.message)

    json_response({:error => @exception.message}, request.path[1..-1])
  end
end
