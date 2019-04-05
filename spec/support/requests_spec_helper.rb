module RequestSpecHelper
  # Parse JSON response to ruby hash
  def json
    JSON.parse(response.body)
  end

  def api(version = 1.0)
    "/api/v#{version}"
  end

  def bypass_tenancy
    with_modified_env(:BYPASS_TENANCY => 'true') { yield }
  end

  def bypass_rbac
    with_modified_env(:BYPASS_RBAC => 'true') { yield }
  end
end
