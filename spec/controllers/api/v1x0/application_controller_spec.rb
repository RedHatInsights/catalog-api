RSpec.describe ApplicationController, :type => :request do
  let(:tenant) { create(:tenant, :external_tenant => default_user_hash['identity']['account_number']) }
  let(:portfolio)         { Portfolio.create!(:name => 'tenant_portfolio', :description => 'tenant desc', :tenant_id => tenant.id, :owner => 'wilma') }
  let(:portfolio_id)      { portfolio.id }

  context "with api version v1" do
    around do |example|
      bypass_rbac do
        example.call
      end
    end

    let(:api_version)       { api(1) }
    let(:api_minor_version) { api(1.0) }

    it "get api/v1/portfolios with tenant" do
      get("#{api_version}/portfolios/#{portfolio_id}", :headers => default_headers)
      expect(response.status).to eq(302)
      expect(response.headers["Location"]).to eq "#{api_minor_version}/portfolios/#{portfolio_id}"
    end

    it "get api/v1/portfolios without tenant" do
      headers = { "CONTENT_TYPE" => "application/json" }

      get("#{api_version}/portfolios/#{portfolio_id}", :headers => headers)
      expect(response.status).to eq(302)
      expect(response.headers["Location"]).to eq "#{api_minor_version}/portfolios/#{portfolio_id}"
    end
  end

  context "with tenancy enforcement" do
    around do |example|
      bypass_rbac do
        example.call
      end
    end

    it "get /portfolios with tenant" do
      get("/api/v1.0/portfolios/#{portfolio_id}", :headers => default_headers)

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

  context "with entitlement enforcement" do
    around do |example|
      bypass_rbac do
        example.call
      end
    end

    let(:false_hash) do
      false_hash = default_user_hash
      false_hash["entitlements"]["hybrid_cloud"]["is_entitled"] = false
      false_hash
    end
    let(:missing_hash) do
      missing_hash = default_user_hash
      missing_hash.delete("entitlements")
      missing_hash
    end

    it "fails if the hybrid_cloud entitlement is false" do
      headers =  { 'x-rh-identity' => encoded_user_hash(false_hash), 'x-rh-insights-request-id' => 'gobbledygook' }
      get "#{api("1.0")}/portfolios", :headers => headers

      expect(response).to have_http_status(:forbidden)
    end

    it "allows the request through if entitlements isn't present" do
      headers = { 'x-rh-identity' => encoded_user_hash(missing_hash), 'x-rh-insights-request-id' => 'gobbledygook' }
      get "#{api("1.0")}/portfolios", :headers => headers

      expect(response).to have_http_status(:ok)
    end
  end
end
