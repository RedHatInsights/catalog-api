RSpec.describe StatusController, :type => :request do
  let(:headers) { {"CONTENT_TYPE" => "application/json"} }
  let(:json) { JSON.parse(response.body) }

  before do
    stub_const("ENV", "BYPASS_TENANCY" => true)
    stub_const("ENV", "DATABASE_URL" => "postgres://admin:smartvm@localhost/insights_api_common_development?pool=5")
  end

  context "when the application is healthy" do
    it "returns a 200" do
      get "/health", :headers => headers
      expect(response).to have_http_status 200
    end
  end

  context "when the application is not healthy" do
    before do
      allow(PG::Connection).to receive(:ping)
        .with(ENV['DATABASE_URL'].split("?").first)
        .and_return PG::Connection::PQPING_NO_RESPONSE
    end

    it "returns a 500" do
      get "/health", :headers => headers
      expect(response).to have_http_status 500
    end
  end
end
