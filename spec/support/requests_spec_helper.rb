require "support/default_as_json"

module RequestSpecHelper
  RSpec.configure do |config|
    config.before(:example, :type => :request) do
      allow(Rails.application.config.action_dispatch).to receive(:show_exceptions)
      allow(Rails.application.config).to receive(:consider_all_requests_local).and_return(false)
    end

    config.include DefaultAsJson, :type => :request
  end

  # Parse JSON response to ruby hash
  def json
    JSON.parse(response.body)
  end

  def api(version = 1.0)
    "/api/v#{version}"
  end

  def bypass_rbac
    with_modified_env(:BYPASS_RBAC => 'true') { yield }
  end
end
