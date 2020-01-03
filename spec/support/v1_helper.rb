module V1Helper
  RSpec.shared_context "API Version 1.0" do
    let(:api_version) { api("1.0") }
  end
  RSpec.configure do |config|
    config.include_context "API Version 1.0"
  end
end
