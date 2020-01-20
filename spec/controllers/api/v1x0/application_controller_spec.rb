RSpec.describe ApplicationController, :type => [:request, :v1] do
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

  context "with tenancy enforcement" do
    around do |example|
      bypass_rbac do
        example.call
      end
    end

    it "get /portfolios with tenant" do
      get("#{api_version}/portfolios/#{portfolio_id}", :headers => default_headers)
      expect(response.status).to eq(200)
      expect(response.parsed_body).to include("id" => portfolio_id.to_s)
    end

    it "get /portfolios without tenant" do
      headers = { "CONTENT_TYPE" => "application/json" }

      get("#{api_version}/portfolios/#{portfolio_id}", :headers => headers)

      expect(response.content_type).to eq("application/json")
      expect(response.status).to eq(401)
    end

    it "get /portfolios with tenant" do
      portfolio
      get("#{api_version}/portfolios", :headers => default_headers)
      expect(response.status).to eq(200)
    end

    it "get /portfolios without tenant" do
      headers = { "CONTENT_TYPE" => "application/json" }

      get("#{api_version}/portfolios", :headers => headers)

      expect(response.content_type).to eq("application/json")
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
      false_hash["entitlements"]["ansible"]["is_entitled"] = false
      false_hash
    end
    let(:missing_hash) do
      missing_hash = default_user_hash
      missing_hash.delete("ansible")
      missing_hash
    end

    it "fails if the ansible entitlement is false" do
      headers =  { 'x-rh-identity' => encoded_user_hash(false_hash), 'x-rh-insights-request-id' => 'gobbledygook' }
      get "#{api_version}/portfolios", :headers => headers

      expect(response.content_type).to eq("application/json")
      expect(response).to have_http_status(:forbidden)
    end

    it "allows the request through if entitlements isn't present" do
      headers = { 'x-rh-identity' => encoded_user_hash(missing_hash), 'x-rh-insights-request-id' => 'gobbledygook' }
      get "#{api_version}/portfolios", :headers => headers

      expect(response).to have_http_status(:ok)
    end
  end
end
