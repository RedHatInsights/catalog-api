module Response
  def json_response(object, status = :ok)
    render :json => object, :status => status
  end

  def topology_service_error(err)
    render :json => {:message => err.message}, :status => :internal_server_error
  end

  def forbidden_error(err)
    Rails.logger.error("Forbidden error: #{err.message}")
    render :json => {:message => "Forbidden"}, :status => :forbidden
  end

  def unauthorized_error(err)
    Rails.logger.error("Unauthorized error: #{err.message}")
    render :json => {:message => "Unauthorized"}, :status => :unauthorized
  end

  def unprocessable_entity_error(err)
    Rails.logger.error("Unprocessable Entity error: #{err.message}")
    render :json => {:message => "Unprocessable Entity"}, :status => :unprocessable_entity
  end
end
