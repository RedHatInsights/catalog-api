RSpec.describe ApplicationController, :type => :request do

  let(:tenant)            { Tenant.create(:external_tenant => external_tenant) }
  let(:portfolio)         { Portfolio.create!(:name => 'tenant_portfolio', :description => 'tenant desc', :tenant_id => tenant.id) }
  let(:portfolio_id)      { portfolio.id }
  let!(:external_tenant)  { (Time.zone.now.to_i * rand(1000)).to_s }
  let(:identity)          { Base64.encode64({'identity' => { 'account_number' => external_tenant}}.to_json) }

  context "with tenancy enforcement" do
    after  { controller.send(:set_current_tenant, nil) }

    it "get /portfolios with tenant" do
      headers = { "CONTENT_TYPE" => "application/json", "x-rh-identity" => identity }

      get("/api/v0.0/portfolios/#{portfolio_id}", :headers => headers)

      expect(response.status).to eq(200)
      expect(response.parsed_body).to include("id" => portfolio_id)
    end

    it "get /portfolios without tenant" do
      headers = { "CONTENT_TYPE" => "application/json" }

      get("/api/v0.0/portfolios/#{portfolio_id}", :headers => headers)

      expect(response.status).to eq(401)
    end

    it "get /portfolios with tenant" do
      portfolio
      headers = { "CONTENT_TYPE" => "application/json", "x-rh-identity" => identity }
      get("/api/v0.0/portfolios", :headers => headers)
      expect(response.status).to eq(200)
    end

    it "get /portfolios without tenant" do
      headers = { "CONTENT_TYPE" => "application/json" }

      get("/api/v0.0/portfolios", :headers => headers)

      expect(response.status).to eq(401)
    end
  end

  context "without tenancy enforcement" do
    before { disable_tenancy }
    after { controller.send(:set_current_tenant, nil) }

    it "get /portfolios" do
      headers = { "CONTENT_TYPE" => "application/json" }

      get("/api/v0.0/portfolios", :headers => headers)

      expect(response.status).to eq(200)
    end
  end
end
