RSpec.describe ApplicationController, :type => [:request, :v1] do
  let(:portfolio) { create(:portfolio, :name => 'tenant_portfolio', :description => 'tenant desc', :owner => 'wilma') }
  let(:portfolio_id) { portfolio.id }
  let(:catalog_access) { instance_double(Insights::API::Common::RBAC::Access, :scopes => %w[admin]) }
  before do
     allow(Insights::API::Common::RBAC::Access).to receive(:new).and_return(catalog_access)
     allow(catalog_access).to receive(:process).and_return(catalog_access)
     allow(catalog_access).to receive(:accessible?).with("portfolios", "create").and_return(true)
     allow(catalog_access).to receive(:admin_scope?).with("portfolios", "update").and_return(true)
  end

  context "with tenancy enforcement" do
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
