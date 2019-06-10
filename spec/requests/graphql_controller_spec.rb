RSpec.describe("v1.0 - GraphQL") do
  let!(:ext_tenant_a) { rand(1000).to_s }
  let!(:identity_a)   { Base64.encode64({'identity' => { 'account_number' => ext_tenant_a }}.to_json) }
  let!(:tenant_a)     { Tenant.create!(:name => "tenant_a", :external_tenant => ext_tenant_a) }
  let!(:portfolio_a)  { Portfolio.create!(:tenant_id => tenant_a.id, :name => "test_a", :owner => "234") }

  let!(:ext_tenant_b) { rand(1000).to_s }
  let!(:identity_b)   { Base64.encode64({'identity' => { 'account_number' => ext_tenant_b }}.to_json) }
  let!(:tenant_b)     { Tenant.create!(:name => "tenant_b", :external_tenant => ext_tenant_b) }
  let!(:portfolio_b)  { Portfolio.create!(:tenant_id => tenant_b.id, :name => "test_b", :owner => "123") }

  let!(:graphql_source_query) { { "query" => "{ portfolios { edges { node { id tenant_id name } } } }" }.to_json }

  def result_portfolio_tenant_ids(response_body)
    JSON.parse(response_body).fetch_path("data", "portfolios", "edges").collect { |edge| edge.fetch_path("node", "tenant_id").to_i }
  end

  context "with tenancy enforcement" do
    before { stub_const("ENV", "BYPASS_TENANCY" => nil) }

    it "querying sources as tenant_a only return tenant_a's sources" do
      headers = { "CONTENT_TYPE" => "application/json", "x-rh-identity" => identity_a }

      post("/api/v1.0/graphql", :headers => headers, :params => graphql_source_query)
      expect(response.status).to eq(200)
      expect(result_portfolio_tenant_ids(response.body)).to match_array([tenant_a.id])
    end

    it "querying sources as tenant_b only return tenant_b's sources" do
      headers = { "CONTENT_TYPE" => "application/json", "x-rh-identity" => identity_b }

      post("/api/v1.0/graphql", :headers => headers, :params => graphql_source_query)

      expect(response.status).to eq(200)
      expect(result_portfolio_tenant_ids(response.body)).to match_array([tenant_b.id])
    end
  end

  context "without tenancy enforcement" do
    before { stub_const("ENV", "BYPASS_TENANCY" => "true") }

    it "querying sources without identity returns all sources" do
      headers = { "CONTENT_TYPE" => "application/json" }

      post("/api/v1.0/graphql", :headers => headers, :params => graphql_source_query)

      expect(response.status).to eq(200)
      expect(result_portfolio_tenant_ids(response.body)).to match_array([tenant_a.id, tenant_b.id])
    end
  end
end
