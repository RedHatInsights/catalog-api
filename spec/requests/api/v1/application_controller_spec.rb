RSpec.describe ApplicationController, :type => [:request, :v1x2] do
  let(:portfolio) { create(:portfolio, :name => 'tenant_portfolio', :description => 'tenant desc', :owner => 'wilma') }
  let(:portfolio_id) { portfolio.id }
  let(:catalog_access) { instance_double(Insights::API::Common::RBAC::Access, :scopes => %w[admin]) }
  before do
     allow(Insights::API::Common::RBAC::Access).to receive(:new).and_return(catalog_access)
     allow(catalog_access).to receive(:process).and_return(catalog_access)
     allow(catalog_access).to receive(:accessible?).with("portfolios", "create").and_return(true)
     allow(catalog_access).to receive(:admin_scope?).with("portfolios", "update").and_return(true)
  end

  context "with api version v1" do
    it "get api/catalog/v1/portfolios with tenant" do
      get("/api/catalog/v1/portfolios/#{portfolio_id}", :headers => default_headers)
      expect(response.status).to eq(302)
      expect(response.headers["Location"]).to eq "#{api_version}/portfolios/#{portfolio_id}"
    end

    it "get api/catalog/v1/portfolios without tenant" do
      headers = { "CONTENT_TYPE" => "application/json" }

      get("/api/catalog/v1/portfolios/#{portfolio_id}", :headers => headers)
      expect(response.status).to eq(302)
      expect(response.headers["Location"]).to eq "#{api_version}/portfolios/#{portfolio_id}"
    end
  end
end
