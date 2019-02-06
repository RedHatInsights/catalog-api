module RequestSpecHelper
  # Parse JSON response to ruby hash
  def json
    JSON.parse(response.body)
  end

  def api(version = 0.0)
    "/api/v#{version}"
  end

  def disable_tenancy
    stub_const("ENV", "BYPASS_TENANCY" => "true")
  end
end
