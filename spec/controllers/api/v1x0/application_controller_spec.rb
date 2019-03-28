RSpec.describe ApplicationController, :type => :request do

  let(:tenant)            { Tenant.create(:external_tenant => external_tenant) }
  let(:portfolio)         { Portfolio.create!(:name => 'tenant_portfolio', :description => 'tenant desc', :tenant_id => tenant.id, :owner => 'wilma') }
  let(:portfolio_id)      { portfolio.id }
  let(:external_tenant)   { "0369233" }
  let(:other_user)        { default_user_hash }

  context "with api version v1" do
    let(:api_version)       { api(1) }
    let(:api_minor_version) { api(1.0) }

    it "get api/v1/portfolios with tenant" do
      get("#{api_version}/portfolios/#{portfolio_id}", :headers => default_headers)
      expect(response.status).to eq(301)
      expect(response.headers["Location"]).to eq "#{api_minor_version}/portfolios/#{portfolio_id}"
    end

    it "get api/v1/portfolios without tenant" do
      headers = { "CONTENT_TYPE" => "application/json" }

      get("#{api_version}/portfolios/#{portfolio_id}", :headers => headers)
      expect(response.status).to eq(301)
      expect(response.headers["Location"]).to eq "#{api_minor_version}/portfolios/#{portfolio_id}"
    end
  end

  context "with tenancy enforcement" do

    it "get /portfolios with tenant" do
      get("/api/v1.0/portfolios/#{portfolio_id}", :headers => admin_headers)

      expect(response.status).to eq(200)
      expect(response.parsed_body).to include("id" => portfolio_id.to_s)
    end

    it "get /portfolios without tenant" do
      headers = { "CONTENT_TYPE" => "application/json" }

      get("/api/v1.0/portfolios/#{portfolio_id}", :headers => headers)

      expect(response.status).to eq(401)
    end

    it "get /portfolios with tenant" do
      portfolio
      get("/api/v1.0/portfolios", :headers => default_headers)
      expect(response.status).to eq(200)
    end

    it "get /portfolios without tenant" do
      headers = { "CONTENT_TYPE" => "application/json" }

      get("/api/v1.0/portfolios", :headers => headers)

      expect(response.status).to eq(401)
    end
  end

  context "without tenancy enforcement" do
    around do |example|
      bypass_tenancy do
        example.call
      end
    end

    it "get /portfolios" do
      headers = { "CONTENT_TYPE" => "application/json" }

      get("/api/v1.0/portfolios", :headers => headers)

      expect(response.status).to eq(200)
    end
  end
end
