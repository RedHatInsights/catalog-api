RSpec.describe ApplicationController, :type => [:request, :v1x1] do
  let(:portfolio) { create(:portfolio, :name => 'tenant_portfolio', :description => 'tenant desc', :owner => 'wilma') }
  let(:portfolio_id) { portfolio.id }

  context "with api version v1" do
    around do |example|
      bypass_rbac do
        example.call
      end
    end

    it "get api/v1/portfolios with tenant" do
      get("/api/v1/portfolios/#{portfolio_id}", :headers => default_headers)
      expect(response.status).to eq(302)
      expect(response.headers["Location"]).to eq "#{api_version}/portfolios/#{portfolio_id}"
    end

    it "get api/v1/portfolios without tenant" do
      headers = { "CONTENT_TYPE" => "application/json" }

      get("/api/v1/portfolios/#{portfolio_id}", :headers => headers)
      expect(response.status).to eq(302)
      expect(response.headers["Location"]).to eq "#{api_version}/portfolios/#{portfolio_id}"
    end
  end
end
